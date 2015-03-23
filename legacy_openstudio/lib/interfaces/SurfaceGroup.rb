# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/interfaces/DrawingInterface")
require("legacy_openstudio/lib/observers/InstanceObserver")
require("legacy_openstudio/lib/observers/SurfaceGroupObserver")
require("legacy_openstudio/lib/observers/SurfaceGroupEntitiesObserver")


module LegacyOpenStudio

  class SurfaceGroup < DrawingInterface

    attr_accessor :show_origin


    def initialize
      super
      @show_origin = false
      @observer = SurfaceGroupObserver.new(self)
      @instance_observer = InstanceObserver.new  # This is a kludge to get onClose callbacks for the Group.
      @entities_observer = SurfaceGroupEntitiesObserver.new(self)
    end


##### Begin override methods for the input object #####


    def update_input_object
      super

      if (valid_entity?)
        # All enclosed entities must be transformed.
        # Could alternatively loop through the base surfaces, subsurfaces, and attached shading surfaces registered with this zone.
        if @entity.is_a? Sketchup::Group
          for entity in @entity.entities
            if (entity.drawing_interface)
              entity.drawing_interface.update_input_object
            end
          end
        end
      end
    end


    # The parent interface is the model interface.
    def parent_from_input_object
      return(Plugin.model_manager.model_interface)
    end


##### Begin override methods for the entity #####


    def create_from_entity_copy(entity)
      super

      remove_observers

      # Copy all of the Group child interfaces.
      # (OR could recurse the children of this SurfaceGroup interface.)
      for child_entity in entity.entities
        if (child_entity.drawing_interface)
          original_surface = child_entity.drawing_interface
          surface_class = original_surface.class
          new_surface = surface_class.new_from_entity_copy(child_entity)
        end
      end

      on_change_entity  # Necessary because the order of copying the child entities may not have updated all the parent references correctly.
      add_observers

      return(self)
    end


    def create_entity
      @entity = Sketchup.active_model.entities.add_group
      set_entity_name

      # Defaults to "@show_origin = false" when opening an input file.
      # Set to true when drawing a new zone with the new zone tool.
      if (@show_origin)
      
# There was warning here that construction point cannot be drawn at 0, 0, 0 but 
# I have not experienced problems with that in either SU 7 or 8
#        if (self.origin == Geom::Point3d.new(0,0,0))
#          # SketchUp apparently doesn't like it if you put a ConstructionPoint at the real origin.
#          # It does add the point, but it just never can be made visible, even if it is inside of a Group.
#          # This workaround shifts the origin to draw the Group initially, then shifts it back.
#          origin_point = self.origin + Geom::Vector3d.new(1, 1, 1)
#          translation = Geom::Transformation.translation(Geom::Vector3d.new(-1, -1, -1))
#        else
          origin_point = self.origin
#          translation = Geom::Transformation.new  # Identity transformation
#        end

        # WARNING:  From the Edit menu, the Delete Guides option will delete all construction points.
        # If a zone is still empty at that time, the zone will be deleted as well!
        cpoint1 = @entity.entities.add_cpoint(origin_point)
        #cpoint1.hidden = true
        cpoint2 = @entity.entities.add_cpoint(origin_point + Geom::Vector3d.new(5.m, 5.m, 3.m))
        cpoint2.hidden = true

#        @entity.transform!(translation)
      end


      # Set the zone rotation and origin
      #z_axis = Geom::Vector3d.new(0, 0, 1)
      #rotation_angle = (-self.azimuth.to_f).degrees
      #rotation = Geom::Transformation.rotation(origin, z_axis, rotation_angle))
      # If the rotation is applied here, probably need to remove rotation applied to surfaces inside the zone.
    end


    def valid_entity?
      # Sometimes 'valid?' still returns true for groups with ambiguous status that should be deleted.
      # 'entityID' is negative if the group is in a semi-deleted state (but is really not valid).
      return(super and @entity.valid? and @entity.entityID > 0)
    end


    # Error checks and cleanup before an entity is accepted by the interface.
    # Return false if the entity cannot be used.
    def check_entity
      if (super)
        if (@entity.class == Sketchup::Group)
          return(true)
        else
          puts "SurfaceGroup.check_entity:  wrong class of entity"
          return(false)
        end
      else
        return(false)
      end
    end


    # Error checks, finalization, or cleanup needed after the entity is drawn.
    def confirm_entity
      if (super)
      
      
      
        return(true)
      else
        return(false)
      end
    end


    # Final cleanup of the entity.
    # This method is called by the model interface after the entire input file is drawn.
    #
    # For SurfaceGroups, cleanup any leftover orphan edges that might remain after some faces were deleted.
    # If anyone wants the edges to persist, this could be a user preference.
    def cleanup_entity
      super
      orphan_edges = []
      for this_entity in @entity.entities
        if (this_entity.class == Sketchup::Edge)
          if (this_entity.faces.empty?)
            # Be careful: looks like calling edge.find_faces will make edge.faces become non-empty
            orphan_edges << this_entity 
            puts "orphan edge!"
          end
        end
      end
      @entity.entities.erase_entities(orphan_edges)
    end


    def clean_entity
      super
      @entity.name = @input_object.fields[1]
    end


    # The parent interface is the model interface.
    def parent_from_entity
      return(Plugin.model_manager.model_interface)
    end


    # Undelete happens when an entity is restored after an Undo event.
    def on_undelete_entity(entity)
      super

      remove_observers

      # Undelete all of the child interfaces.
      for child_entity in entity.entities
        if (child_entity.drawing_interface)
          child_entity.drawing_interface.on_undelete_entity(child_entity)
        end
      end

      add_observers
    end


    def group_entity
      return(@entity)
    end


##### Begin override methods for the interface #####


    def add_observers
      super
      if (valid_entity?)
        @entity.add_observer(@instance_observer)
        @entity.entities.add_observer(@entities_observer)
      end
    end


    def remove_observers
      super
      if (valid_entity?)
        @entity.remove_observer(@instance_observer)
        @entity.entities.remove_observer(@entities_observer)
      end
    end


##### Begin new methods for the interface #####


    # Returns the general coordinate transformation from absolute to relative.
    # The 'inverse' method can be called on the resulting transformation to go from relative to absolute.
    # This method should be overridden in subclasses.
    def coordinate_transformation
    end


  end

end
