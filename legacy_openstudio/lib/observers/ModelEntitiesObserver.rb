# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/AsynchProc")


module LegacyOpenStudio

  class ModelEntitiesObserver < Sketchup::EntitiesObserver

    def onElementAdded(entities, entity)
      if (entity.class == Sketchup::Group)
        #puts "ModelEntities.onElementAdded:" + entity.to_s

        if (entity.drawing_interface)
          if (entity.drawing_interface.deleted?)
            # This is a cut-paste/delete-undo event.

            # Important to have put Timers here inside the if-then logic, rather
            # than outside as its done in SurfaceGroupEntitiesObserver.
            # Otherwise if a zone is added with the New Zone Tool, the zone
            # ends up getting added twice.
            AsynchProc.new {
              #puts "cut-paste/delete-undo surface group"

              entity.drawing_interface.on_undelete_entity(entity)
            }

          else
            # This is a copy-paste event.

            AsynchProc.new {
              #puts "copy-paste surface group"

              # At this point SketchUp has created a new Group object for 'entity'.
              # BUT the new Group and the original Group both reference the same ComponentDefinition
              # which has a single Entities object.  That means both groups share the same
              # entities.  Apparently SketchUp doesn't create a new ComponentDefinition until
              # it decides it really needs one.

              # Solution is to "touch" the new Group to force SketchUp to create a new
              # ComponentDefinition and a new Entities object.
              cpoint = entity.entities.add_cpoint(Geom::Point3d.new(0,0,0)) 
              cpoint.erase!

              original_group = entity.drawing_interface
              group_class = original_group.class
              new_group = group_class.new_from_entity_copy(entity)
              new_group.update_entity
            }
          end

        else
          # A new Group entity was added.
          # New zones and shading groups are added with a tool instead of an Observer event.
          # There is nothing to handle here.

        end
      else
        # A class other than Group was added to the Model.

        if (entity.drawing_interface)
          # An EnergyPlus object was pasted outside of a Zone or Shading Group.

          AsynchProc.new {
            #puts "explode/paste object outside of surface group"

            # Clean the entity.  Be careful:  cannot call 'drawing_interface.clean_entity' because it
            # will clean the original drawing interface, not this copy.
            DrawingUtils.clean_entity(entity)
          }
        end
      end

    end


    def onElementRemoved(entities, entity)
      #puts "ModelEntitiesObserver.onElementRemoved"
    end


    # This method gets called for every edge that gets drawn...so gets lots of hits!
    # UPDATE:  Broken in SU6 M3--was working in previous versions!  *args should catch any number of arguments, even none.
    def onContentsModified(*args)
      #puts "ModelEntitiesObserver.onContentsModified"
    end


    # Only gets called when the model closes, I think.
    def onEraseEntities(entities)
      #puts "ModelEntitiesObserver.onEraseEntities"
    end

  end

end
