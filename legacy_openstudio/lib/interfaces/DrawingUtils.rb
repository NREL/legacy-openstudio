# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/sketchup/Sketchup")
require("legacy_openstudio/sketchup/Geom")


# Everything in this module should be strictly based on entities and not drawing interfaces.
module DrawingUtils


  # Strictly determined using Faces, not drawing interfaces.
  # Tries to match a face to a base face.
  def DrawingUtils.detect_base_face(face)
    base_face = nil
    face_points = face.polygon.reduce.points

    for child_entity in face.parent.entities
      if (child_entity.class == Sketchup::Face and not child_entity.equal?(face))
        # Eliminate faces that are not parallel.
        # Another test would be to check if both are in the same plane.
        # There are some precision issues with 'face.plane' however.
        if (child_entity.normal.parallel?(face.normal))
          # Detect if the vertices of the entity are a subset of this face.
          if (face_points.is_subset_of?(child_entity.polygon.reduce.points))
            base_face = child_entity
            break
          end
        end
      end
    end
    return(base_face)
  end


  # Check if this should be a base surface or attached shading.
  # If it is attached shading, the method returns the reference to the base surface drawing interface.
  def DrawingUtils.detect_attached_shading(entity)
    base_surface = nil
    this_polygon = entity.outer_polygon.reduce
    entity.parent.entities.each { |other_entity|
      if ((other_entity.class == Sketchup::Face) and (other_entity != entity))
        if (other_entity.drawing_interface.class == LegacyOpenStudio::BaseSurface)

          other_polygon = other_entity.drawing_interface.face_polygon

          # Check to make sure the outward normal vectors are not parallel in order to eliminate sub surfaces.
          if (not other_polygon.normal.parallel?(entity.normal))
            count = 0
            for point in this_polygon.points
              if (Geom.point_in_polygon(point, other_polygon, false))
                count +=1
                if (count == 2)
                  base_surface = other_entity.drawing_interface
                  break
                end
              end
            end
          end
        end
      end

      if (not base_surface.nil?)
        break
      end
    }
    
    return(base_surface)
  end



  def DrawingUtils.clean_entity(entity)
    # This could be added as a method on Face and Group.

    if (entity.drawing_interface)
      #entity.remove_observer(entity.drawing_interface.observer)
      entity.drawing_interface.remove_observers
    end

    entity.drawing_interface = nil
    entity.input_object_key = nil
    #entity.input_object_fields = nil
    #entity.input_object_context = nil
  end



  # This would be called by sub surface swaps, as well as swaps from push/pull.
  # 'entity1' already has an interface.
  def DrawingUtils.swap_interfaces(entity1, entity2)

  
    #drawing_interface.attach_entity(entity)
        #    detach_entity(@entity)  # fix old entity
        #
        #    check_entity(entity)  ...test before continuing
        #
        #    @entity = entity
        #    @entity.drawing_interface = self
        #    @entity.input_object_key = @input_object.key
        #      ? maybe call on_changed_entity
        #    ##add_observers  (optional)  or do externally

  
    #  .attach_input_object(input_object)
    #      @input_object = input_object
    #      @entity.input_object_key = @input_object.key

  end





  # Big kludge:
  # When a face is divided into two faces such that the smaller face cuts into the original face,
  # e.g., changing the original vertice count from 4 to 8, the entity object assignments will
  # often become swapped.  For example, the 8 vertex face is now considered the 'new entity' and
  # the smaller face is assigned to the original entity.  This is a problem when trying to detect
  # windows and doors that are added.
  # Solution is that both faces will share the same drawing interface at this point.  The task is
  # to identify which is which.

# breaks rule of only looking at entities..but it has to.
  # Checks only the case of swapping a sub_face with a base_face.
  def DrawingUtils.swapped_face_on_divide?(entity)

    # first check if either entity have been deleted
    if entity.drawing_interface.entity.deleted?
      return(false)  # no swap
    end
    
    new_face_points = entity.polygon.reduce.points
    original_face_points = entity.drawing_interface.entity.polygon.reduce.points

    if (new_face_points.is_subset_of?(original_face_points))
      puts "no swap"
      return(false)  # no swap
    else
      puts "swap"
      return(true)  # swapped
    end
  end



  def DrawingUtils.swapped_face_on_pushpull?(entity)   # swal_on_pushpull?
    return(false)
  end


end
