# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/AsynchProc")
require("legacy_openstudio/lib/interfaces/DrawingUtils")


module LegacyOpenStudio

  class SurfaceGroupEntitiesObserver < Sketchup::EntitiesObserver

    def initialize(drawing_interface)
      @drawing_interface = drawing_interface
    end


    def onElementAdded(entities, entity)
      # Enclosing everything inside of a Timer is necessary otherwise SketchUp can
      # lock up if you try to set attributes on 'entity'.  Remember that setting
      # 'entity.drawing_interface = nil' actually sets an attribute.
      AsynchProc.new {
        if (entity.class == Sketchup::Face and not entity.deleted?)  # In SU7, deleted entities get passed in sometimes.
          puts "SurfaceGroupEntitiesObserver.onElementAdded:" + entity.to_s

          # Prevent copy-paste between a zone group and a detached shading group.
          # Clean any entities that appear with the wrong class for this group.
          if (entity.drawing_interface)
            if (@drawing_interface.class == Zone)
              if (entity.drawing_interface.class == DetachedShadingSurface)
                DrawingUtils.clean_entity(entity)
              end
            elsif (@drawing_interface.class == DetachedShadingGroup)
              if (entity.drawing_interface.class != DetachedShadingSurface)
                DrawingUtils.clean_entity(entity)
              end
            end
          end

          if (entity.drawing_interface.nil?)
            #  This is a brand new surface.

            if (@drawing_interface.class == Zone)
              base_surface = DrawingUtils.detect_attached_shading(entity)
              if (base_surface)
                puts "new attached shading surface"
                AttachedShadingSurface.new_from_entity(entity)            
              else
                puts "new base surface"
                BaseSurface.new_from_entity(entity)
              end
            elsif (@drawing_interface.class == DetachedShadingGroup)
              puts "new detached shading surface"
              DetachedShadingSurface.new_from_entity(entity)
            else
              puts "SurfaceGroupEntitiesObserver.onElementAdded:  unhandled SurfaceGroup subclass"
            end

          elsif (entity.drawing_interface.deleted?)
            # This is a cut/paste or undo of a previous delete of this surface.
            puts "cut-paste/delete-undo surface"
            entity.drawing_interface.on_undelete_entity(entity)
            
            
            # May have to handle swapping in here too.
            if (swapped = DrawingUtils.swapped_face_on_divide?(entity))
              puts "swapped!!!!!"
            else
              puts "no swaps asdfasdf"
            end
            

          else
            # This is a divide of an existing surface.
            # A divide can be caused by drawing a line that divides a face, or by push/pull.
            # This also gets called for a copy and paste.
            # If this is a divide, the parent face vertices have already changed.
            # This could be a divide of a base surface, or a new window or door subsurface.
            #puts "copy-paste/divide/push-pull surface"

            # This falsely detects a copy-paste of a base surface in the same zone as a swap.  It's not.
            swapped = DrawingUtils.swapped_face_on_divide?(entity)

            if (@drawing_interface.class == Zone)
              if (swapped)
                base_face = DrawingUtils.detect_base_face(entity.drawing_interface.entity)
              else
                base_face = DrawingUtils.detect_base_face(entity)
              end
            else
              base_face = nil
            end

            if (base_face.nil?)
              # This is a copy-paste/divide/push-pull of a surface.
              # New surface should belong to the same class as the original.

              surface_class = entity.drawing_interface.class

              case (Sketchup.active_model.tools.active_tool_id)
              when (21041)  # PushPullTool
                puts "push-pull surface:  new surface"
                surface_class.new_from_entity(entity)
              #when (21020)  # SketchTool (Line/Pencil)
              #when (21094)  # RectangleTool
              #when (21013)  # PasteTool
              #when (21048)  # MoveTool  (also gets called when doing a multi-copy/paste)
              else
                puts "copy-paste/divide surface:  copy surface"
                surface_class.new_from_entity_copy(entity)
              end


            else  
              # This is a new sub surface located on a base surface.

              # NEED SEPARATE TOOL HANDLER HERE
              #  swapping happens differently for subsurfaces and push/pull


              if (swapped)
                # Original face and new face were swapped!
                # Fix the original surface drawing interface so that it points to the new face.
                puts "copy-paste/divide surface:  new sub surface; swap!"

                # Save the original entity to become the *new* surface below.
                original_entity = entity.drawing_interface.entity

                original_surface = entity.drawing_interface
                original_surface.remove_observers

                original_surface.entity = entity
                original_surface.entity.drawing_interface = original_surface
                original_surface.entity.input_object_key = original_surface.input_object.key

                original_surface.on_change_entity  # Recalculates vertices and paints the new entity.
                original_surface.add_observers

                new_surface = SubSurface.new_from_entity(original_entity)

              else
                # Normal sub surface--no swapping.
                puts "copy-paste/divide surface:  new sub surface; no swap"
                original_surface = entity.drawing_interface

                SubSurface.new_from_entity(entity)
                
                # Must trigger the base surface to recalculate vertices to account for the new sub surface.
                original_surface.on_change_entity
                
              end
            end
          end
        
        else
 
          if (not entity.deleted?)
            if (drawing_interface = entity.drawing_interface)
            
              need_to_remove = false
              already_exists = false
              error_message = ""
            
              if (drawing_interface.class == DaylightingControls)
                puts "new daylighting controls"
                
                if (@drawing_interface.class == Zone)
                
                  # see if we already have this object
                  Plugin.model_manager.daylighting_controls.each do |daylighting_controls| 
                    if daylighting_controls.entity == entity
                      already_exists = true
                    elsif daylighting_controls.zone == @drawing_interface.input_object
                      need_to_remove = true
                      error_message = "Zone #{@drawing_interface.input_object} already has Daylighting:Controls"
                      break
                    end
                  end
                  
                  if not already_exists and not need_to_remove 
                    new_entity = DaylightingControls.new_from_entity(entity)
                  end
               
                else 
                  # not added to a zone
                  need_to_remove = true
                  error_message = "Can only add DaylightingControls to a Zone"
                end
                
              elsif(drawing_interface.class == OutputIlluminanceMap)
                puts "new output illuminance map"
                
                if (@drawing_interface.class == Zone)
                
                  # see if we already have this object
                  Plugin.model_manager.output_illuminance_maps.each do |output_illuminance_map| 
                    if output_illuminance_map.entity == entity
                      already_exists = true
                    elsif output_illuminance_map.zone == @drawing_interface.input_object
                      need_to_remove = true
                      error_message = "Zone #{@drawing_interface.input_object} already has an Output:IlluminanceMap"
                      break
                    end
                  end
                  
                  if not already_exists and not need_to_remove 
                    new_entity = OutputIlluminanceMap.new_from_entity(entity)
                  end
               
                else 
                  # not added to a zone
                  need_to_remove = true
                  error_message = "Can only add Output:IlluminanceMap to a Zone"
                end
                             
              end

              if need_to_remove
                DrawingUtils.clean_entity(entity)
                Sketchup.active_model.entities.erase_entities(entity)
                Sketchup.send_action("selectSelectionTool:")
                UI.messagebox(error_message)
              end
              
            else
              puts "unknown object added"
            end
            
          end
          
        end
        
        # This is also getting called in DrawingInterface in a couple places.
        # Should probably standardize...call in observers?  or call in an 'on_event' method in DrawingInterface?
        Plugin.dialog_manager.update(ObjectInfoInterface)
        
      }  # AsynchProc
    end


    def onElementRemoved(entities, entity)
      #puts "SurfaceGroupEntitiesObserver.onElementRemoved:" + entity.to_s
    end


    # This method gets called for every edge that gets drawn...so gets lots of hits!
    # UPDATE:  Broken in SU 6M3--was working in previous versions!  *args should catch any number of arguments, even none.
    def onContentsModified(*args)
      puts "SurfaceGroupEntitiesObserver.onContentsModified"
    end


    # Gets called when ALL entities are deleted, but only if the group is closed, or after the group is closed.
    # This would be a good place to prompt if the user wants to erase the zone completely.
    def onEraseEntities(entities)
      #puts "SurfaceGroupEntitiesObserver.onEraseEntities"
    end

  end

end
