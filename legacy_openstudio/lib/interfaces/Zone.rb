# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/interfaces/SurfaceGroup")


module LegacyOpenStudio

  class Zone < SurfaceGroup

    def initialize
      super
      $z = self
    end

    def name
      return @input_object.fields[1]
    end
    
##### Begin override methods for the input object #####


    def create_input_object
      @input_object = InputObject.new("ZONE")
      @input_object.fields[1] = Plugin.model_manager.input_file.new_unique_object_name
      @input_object.fields[2] = "0.0"  # Relative North
      @input_object.fields[3] = "0.0"  # X Origin
      @input_object.fields[4] = "0.0"  # Y Origin
      @input_object.fields[5] = "0.0"  # Z Origin
      @input_object.fields[6] = ""  # Type
      @input_object.fields[7] = "1"  # Multiplier

      super
    end


    def update_input_object
      super

      if (valid_entity?)

        # Automatically check for interzone surfaces!
        # --User option to turn this off (if too slow)
        return

        this_bounding_box = @entity.bounds
        for other_entity in @entity.parent.entities  # this should be the model entities, but might be nested, I suppose
          # Make sure this is an EnergyPlus entity
          if (other_entity.drawing_interface and (other_entity != @entity))
            # NOTE:  There could be more than one intersection!

            other_bounding_box = other_entity.bounds

            # Hoped to use native method 'intersect' which returns a bounding_box
            # but there is an API bug, so it does not work correctly.
            #intersection = this_bounding_box.intersect(other_bounding_box)
            #if (not intersection.empty?)
            # Instead, I added my own method 'intersects?' that just does a true/false test.
            if (this_bounding_box.intersects?(other_bounding_box))
              #puts "found intersection!"

              if (Plugin.read_pref("Play Sounds"))
                UI.play_sound(Plugin.dir + "lib/resources/pop.wav")
              end


              for this_child_entity in @entity.entities
                if (this_child_entity.class == Sketchup::Face)
                  for other_child_entity in other_entity.entities
                    if (other_child_entity.class == Sketchup::Face)

                      # assume they have drawing interfaces...

                      points = this_child_entity.drawing_interface.surface_absolute_polygon
                      other_points = other_child_entity.drawing_interface.surface_absolute_polygon

                      #puts "points"
                      #puts points
                      #puts "other_points"
                      #puts other_points
                      #puts
                      #puts

                      # the below are not good because they are relative
                      #puts "entity.points"
                      #this_child_entity.vertices.each { |v| puts v.position }
                      #puts "entity.other_points"
                      #other_child_entity.vertices.each { |v| puts v.position }

                      #points = []
                      #this_child_entity.vertices.each { |v| points << v.position }
                      #other_points = []
                      #this_child_entity.vertices.each { |v| other_points << v.position }

                      # ACk!  can't do a face intersect here because group coordinate systems are different...
                      #if (loops = Geom.intersect_polygon_polygon(points, other_points))
                      #  puts "loops found!"
                      #  puts loops


                        # The next trick is to add faces to each group...
                        # Need to convert back from world coords ('loops') to relative coords for each Group.



                      #  loops.each { |this_loop| Sketchup.active_model.entities.add_face(this_loop) }
                      #end


                    end
                  end
                end
              end


            end
          end
        end
      end
    end


##### Begin override methods for the entity #####


    # Updates the SketchUp entity with new information from the EnergyPlus object.
    # Apply a transformation to update the zone origin and zone axis.
    def update_entity
      super
      if (valid_entity?)
        set_entity_name
        
        # update children
        @entity.entities.each do |entity|
          if (drawing_interface = entity.drawing_interface)
            if drawing_interface.is_a? OutputIlluminanceMap or drawing_interface.is_a? DaylightingControls
              entity.drawing_interface.update_entity
            end
          end
        end

        # TO DO:  Apply a transformation to update the zone origin and zone axis.
      end
    end


    # Final cleanup of the entity.
    # This method is called by the model interface after the entire input file is drawn.
    #
    # For zones, check for any problems with its faces.
    def cleanup_entity
      super
      faces = @entity.entities.find_all { |this_entity| this_entity.class == Sketchup::Face }

      for face in faces
        # Check for any faces that were somehow added and did not get a drawing interface (should never happen).
        if (face.drawing_interface.nil?)
          puts "Zone.cleanup_entity:  missing a drawing interface for " + face.to_s
        else

          # Check for any swaps that got under the radar.
          # THIS SHOULD NEVER HAPPEN!  THIS IS NOW BEING TRAPPED BY EACH SURFACE AS IT IS CREATED.
          # THIS PASS SHOULD BE COMPLETELY REDUNDANT.
          # This can happen when the SketchUp 'add_face' method adds two faces when only one was specified (see below).
          if (face.drawing_interface.entity != face)
            puts "Zone.cleanup_entity:  unhandled swap for " + face.to_s

            # Fix the swap--surprisingly this seems to be sufficient.
            face.drawing_interface.entity = face
          end
        end
      end


      # THIS CAN PROBABLY BE MOVED INTO THE 'CLEANUP_ENTITY' METHOD OF THE DRAWINGINTERFACE FOR SURFACE
      for face in faces
        # Check for any faces with duplicate drawing interfaces
        for other_face in faces

          next if (not face.valid? or not other_face.valid?)
          next if (face.area == 0 or other_face.area == 0)

          if (other_face.drawing_interface == face.drawing_interface and other_face != face)
            puts "Zone.cleanup_entity:  duplicate drawing interface for " + face.to_s + ", " + other_face.to_s

            # Occasionally the SketchUp 'add_face' method will (accidentally?) add two faces when only one was specified.
            # Usually there is some inferred behavior about the base face that leads to one version of the new face being drawn.
            # Meanwhile another version of the new face is also drawn that more accurately matches the vertices that were input.
            # The result is two faces that are coincident yet different.  The new face that is carved out of the base face
            # inherits its drawing interface--this is the duplicate face.

            # Try to find the correct faces and delete the extra one
            # The two coincident faces will have the same reduced outer polygon.

            # Only one of the duplicates ('face' or 'other_face') will match exactly one other face.

            # Try to find a match for 'face'
            found = false
            for test_face in faces
              next if (not test_face.valid?)

              test_face_points = test_face.outer_polygon.reduce.points
              face_points = face.outer_polygon.reduce.points

              if (test_face != face and test_face_points.is_same_set?(face_points))
                intended_face = test_face
                inferred_face = face
                found = true
              end
            end

            # Try to find a match for 'other_face'
            if (not found)
              for test_face in faces
                next if (not test_face.valid?)

                test_face_points = test_face.outer_polygon.reduce.points
                other_face_points = other_face.outer_polygon.reduce.points

                if (test_face != other_face and test_face_points.is_same_set?(other_face_points))
                  #puts "matched other face: " + test_face.to_s + ", " + face.to_s
                  intended_face = test_face
                  inferred_face = other_face
                  found = true
                end
              end
            end

            # 'intended_face' should be the sub face, the one we really wanted in the first place
            # 'inferred_face' should be the one that was added when the API tried to infer (incorrectly) what to do


            if (found)
              # Fix the faces
              # The 'intended_face' has the wrong geometry (not connected to base face properly) but the correct drawing interface.                  
              # The 'inferred_face' has the correct geometry, but the wrong drawing interface.

              #puts "intended" + intended_face.to_s + " " + intended_face.vertices.length.to_s
              #puts "inferred" + inferred_face.to_s + " " + inferred_face.vertices.length.to_s


              inferred_face.drawing_interface = intended_face.drawing_interface
              inferred_face.drawing_interface.entity = inferred_face
              inferred_face.drawing_interface.surface_polygon = inferred_face.drawing_interface.face_polygon
              inferred_face.drawing_interface.paint_entity

              @entity.entities.erase_entities(intended_face)

            else
              # This can happen if a face was unintentionally subdivided when another face was drawn.
              #puts "Could not find a coincident face for the duplicate--will create new object"

              if (other_face.drawing_interface.class == BaseSurface)
                new_surface = BaseSurface.new_from_entity(other_face)

              elsif (other_face.drawing_interface.class == SubSurface)
                new_surface = SubSurface.new_from_entity(other_face)

              else # attached shading, detached shading
                #puts "need to add new objects for shading surfaces!"

              end

              Plugin.model_manager.add_error("Warning:  A surface was subdivided because of connected geometry.\n")
              Plugin.model_manager.add_error("Added new surface " + new_surface.input_object.key + "\n")
              Plugin.model_manager.add_error("You should check your geometry carefully for mistakes.\n\n")
            end
          end
        end
      end

    end


    def on_change_entity
      super  # Zone has already been updated in super

      # Check for interzone surfaces
      # --check pref yes/no
      if (valid_entity?)
        this_group = @entity

        this_edges = []
        #puts this_group.class
        for other_entity in Sketchup.active_model.entities
          other_group = other_entity

          if (other_group.class == Sketchup::Group and other_group != this_group)  # and has drawing_interface

            #puts "intersect_with"
            #puts other_group.class

            #this_edges = this_group.entities.intersect_with(false, this_group.transformation, this_group.entities, this_group.transformation, true, [other_group])

            #other_edges = other_group.entities.intersect_with(false, other_group.transformation, other_group.entities, other_group.transformation, true, [this_group])
          end
        end

      end

      # Using the edges returned by intersect_with is not going to work.
      # In the case where one zone is smaller (and therefore does not get any new cuts), none of its edges/faces are returned.
      # Would be impossible to match.
      
      # Plan B.
      # Loop through all faces.
      # Quick Tests:
      #   1. if in same plane (absolute value)    normal must be either same or opposite
      #       2.  if all vertices a coincident  (I think I have routines that test this already)
      #            3.  if normal is in same direction, one surface must be deleted (the target zone usually...the pushed one takes precedence.)
      #
      #            4.  elsif normal is in opposite direction, setup interzone BCs.   Or delete both (air wall).
      #
      #  Now, just how to get rid of penetrating parts of the pushed zone?
      
      # what happens if a window gets cut by the intersect_with?
      
      # special cases:
      #    A BaseSurface pushed into the middle of another zone Base.  Must cut hole and slice to outside!
      #    Option to delete wall and just do Airwall.
      #    Windows contained on inter walls.


    end


##### Begin override methods for the interface #####


    # Returns the general coordinate transformation from absolute to relative.
    # The 'inverse' method can be called on the resulting transformation to go from relative to absolute.
    def coordinate_transformation

      #building_rotation = Plugin.model_manager.building.transformation
      # The building transformation cannot be applied in this way.
      # It has the effect of rotating about the Groups local origin, not the absolute origin.


      absolute_origin = Geom::Point3d.new(0, 0, 0)
      z_axis = Geom::Vector3d.new(0, 0, 1)

      translation_vector = absolute_origin.vector_to(self.origin)
      zone_translation = Geom::Transformation.translation(translation_vector)

      building_angle = (-Plugin.model_manager.building.azimuth).degrees
      building_rotation = Geom::Transformation.rotation(absolute_origin.offset(translation_vector.reverse), z_axis, building_angle)

      # azimuth is not a good word here...rotation or angle is better
      # azimuth is the final direction its facing....not a relative value like it is being used in this context.
      #zone_rotation = Geom::Transformation.rotation(self.origin, z_axis, self.azimuth)
      # I'm not sure I understand this, but the zone must rotate about the origin here.
      zone_rotation = Geom::Transformation.rotation(Geom::Point3d.new(0, 0, 0), z_axis, self.azimuth)

      return(zone_translation * building_rotation * zone_rotation)  # original
    end


##### Begin new methods for the interface #####


    def set_entity_name
      if (@input_object.name.empty?)
        @entity.name = "EnergyPlus Zone:  " + "(Untitled)"
      else
        @entity.name = "EnergyPlus Zone:  " + @input_object.name
      end
    end


    def origin
      if (@input_object.fields[3].nil?)
        puts "Zone.origin:  missing x coordinate"
      end
      
      if (@input_object.fields[4].nil?)
        puts "Zone.origin:  missing y coordinate"
      end

      if (@input_object.fields[5].nil?)
        puts "Zone.origin:  missing z coordinate"
      end      

      x = @input_object.fields[3].to_f.m
      y = @input_object.fields[4].to_f.m
      z = @input_object.fields[5].to_f.m

      return(Geom::Point3d.new(x,y,z))
    end


    def origin=(point)
      decimal_places = Plugin.model_manager.length_precision
      if (decimal_places < 6)
        decimal_places = 6
        # Always keep at least 6 places for now, until I figure out how to keep the actual saved in the idf from being reduced upon loading
        # There's nothing in the API that prevents from drawing at finer precision than the option settings.
        # Just have to figure out how to keep this routine from messing it up...
        # NOTE:  Comment above applies more for surfaces than zones.
      end

      @input_object.fields[3] = point.x.to_m.round_to(decimal_places).to_s
      @input_object.fields[4] = point.y.to_m.round_to(decimal_places).to_s
      @input_object.fields[5] = point.z.to_m.round_to(decimal_places).to_s
    end


    def azimuth
# April'10 - this is being pulled from the building.rb rotation angle
      field = @input_object.fields[2]

      if (field.nil?)
        # post an error log item, ZONE object is missing some fields
        puts "Zone.azimuth:  missing relative north field"
        angle = 0.0
      else
        # a bad value for field (like putting "asdf" instead of "330") does not throw an error
        # when using to_f
        # might want to do my own conversion
        
        # EnergyPlus measures angles with positive values in the clockwise direction.
        # SketchUp measures with positive values in the counter-clockwise direction.

        angle = (-field.to_f).degrees
      end

      return(angle)
    end


    def include_in_building_floor_area?
      if (@input_object.fields[13].nil? or @input_object.fields[13].upcase == "YES")
        return(true)
      else
        return(false)
      end
    end


    def multiplier
      value = @input_object.fields[7].to_i
      if (value > 0)
        return(value)
      else
        return(1)
      end
    end


    def area
    end


    def unit_floor_area
      area = 0.0
      for child in @children
        if (child.class == BaseSurface and child.surface_type.upcase == "FLOOR")
          area += child.gross_area
        end
      end
      return(area)
    end


    def floor_area
      return(self.unit_floor_area * self.multiplier)
    end


    def unit_exterior_area
      area = 0.0
      for child in @children
        if (child.class == BaseSurface and child.input_object.fields[5].upcase == "OUTDOORS")
          area += child.gross_area
        end
      end
      return(area)
    end


    def exterior_area
      # "Total" area, includes multiplier
      return(self.unit_exterior_area * self.multiplier)
    end


    def exterior_glazing_area
      # "Total" area, includes multiplier
      area = 0.0
      for child in @children
        if (child.class == BaseSurface and child.input_object.fields[5].upcase == "OUTDOORS")
          area += child.glazing_area
        end
      end
      return(area)
    end


    def percent_glazing
      if (self.unit_exterior_area > 0.0)
        return(100.0 * self.exterior_glazing_area / self.unit_exterior_area)
      else
        return(0.0)
      end
    end


    # Counts all base surfaces in the zone.
    def base_surface_count
      return(@children.count { |child| child.class == BaseSurface })
    end


    # Counts sub surfaces of all base surfaces and any orphan sub surfaces at the zone level without a base surface.
    def sub_surface_count
      count = @children.count { |child| child.class == SubSurface }  # Orphan sub surfaces
      @children.each { |child| count += child.sub_surface_count if (child.class == BaseSurface) }
      return(count)
    end


  end

end
