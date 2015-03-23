# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/interfaces/DrawingUtils")
require("legacy_openstudio/lib/interfaces/Surface")
require("legacy_openstudio/lib/inputfile/InputObject")


module LegacyOpenStudio

  class SubSurface < Surface

    def initialize
      super
      @first_vertex_field = 11
    end


    def create_input_object
      @input_object = InputObject.new("FENESTRATIONSURFACE:DETAILED")
      @input_object.fields[1] = Plugin.model_manager.input_file.new_unique_object_name
      @input_object.fields[2] = default_surface_type
      @input_object.fields[3] = ""  
      @input_object.fields[4] = ""  # Base Surface
      @input_object.fields[5] = ""
      @input_object.fields[6] = ""
      @input_object.fields[7] = ""
      @input_object.fields[8] = ""
      @input_object.fields[9] = ""
      
      @input_object.fields[3] = default_construction # do after setting boundary conditions

      @input_object.fields[12] = 0  # kludge to make fields list long enough for call below 

      super
    end
    

    def check_input_object
      # All base surfaces should already be drawn.

      if (super)

        # OTHER CHECKS TO DO:
        # Subsurface that is the same size as its base surface...fix so that slightly inset.
        # Subsurface that subdivides a base surface...fix so that slightly inset.


        # This is the wrong place to do this, but no one else has set '@parent' yet, which is relied on by 'surface_polygon' later.
        @parent = parent_from_input_object   


        # Check the base surface
        parent = @parent
        if (parent.class != BaseSurface)
          Plugin.model_manager.add_error("Error:  " + @input_object.key + "\n")
          Plugin.model_manager.add_error("This sub surface is missing its base surface: " + @input_object.fields[4].to_s + "\n")
          Plugin.model_manager.add_error("A new zone object has been automatically created for this surface.\n")
          Plugin.model_manager.add_error("However it is still missing a base surface.\n")

        else

          # Disable the preference to turn off the automatic projection of sub surfaces.
          # Currently this would unassign all the base surface references if the sub is not in the same plane.
          #if (Plugin.read_pref("Project Sub Surfaces"))
            # Check if the sub surface is coplanar with the base surface
            plane = parent.face_polygon.plane

            coplanar = true
            coplanar_points = []

            for point in surface_polygon.points
              coplanar_points << point.project_to_plane(plane)
              if (not point.on_plane?(plane))
                # point.on_plane? apparently has a greater tolerance than Sketchup in general.
                # Sub surfaces that pass this test still show up as not entirely coplanar with the base surface (thick lines).
                coplanar = false
              end
            end

            # Always fix the points to be coplanar because tolerances are different above.
            # Could still be user preference to fix or not.
            # This is a problem because reveals are done as inset surface that are NOT in the same plane!
            self.surface_polygon = Geom::Polygon.new(coplanar_points)

            if (not coplanar)
              Plugin.model_manager.add_error("Warning:  " + @input_object.key + "\n")
              Plugin.model_manager.add_error("This sub surface was not in the same plane as its base surface.\n")
              Plugin.model_manager.add_error("It has been automatically fixed.\n\n")
            end
          #end


          # Check if the sub surface is inside-out
          if ((Plugin.model_manager.surface_geometry.input_object.fields[2].upcase == "COUNTERCLOCKWISE" and not surface_polygon.normal.samedirection?(parent.entity.normal)) \
            or (Plugin.model_manager.surface_geometry.input_object.fields[2].upcase == "CLOCKWISE" and surface_polygon.normal.samedirection?(parent.entity.normal)))
            Plugin.model_manager.add_error("Warning:  " + @input_object.key + "\n")
            Plugin.model_manager.add_error("This sub surface is inside-out; outward normal does not match its base surface.\n")
            Plugin.model_manager.add_error("It has been automatically fixed.\n\n")

            # Always fix this error.

            # Better to add a 'reverse!' method to Surface.
            self.input_object_polygon = self.input_object_polygon.reverse
          end


          # Check if the sub surface is contained by the base surface
          contained = true
          for point in surface_polygon.points
            if (not parent.entity.contains_point?(point, true))
              contained = false
              # Not sure how to fix this one without accidentally overlapping with another surface
              break
            end
          end

          if (not contained)
            Plugin.model_manager.add_error("Error:  " + @input_object.key + "\n")
            Plugin.model_manager.add_error("This sub surface is not contained by its base surface.\n\n")
          end
        end

        return(true)
      else
        return(false)
      end
    end


    # Updates the input object with the current state of the entity.
    def update_input_object
      super  # Surface superclass updates the vertices

      if (valid_entity?)
        if (@parent.class == BaseSurface)
          @input_object.fields[4] = @parent.input_object  # Parent should already have been updated.
        else
          @input_object.fields[4] = ""
        end
      end
    end


    # Returns the parent drawing interface according to the input object.
    def parent_from_input_object
      parent = nil
      if (@input_object)
        parent = Plugin.model_manager.base_surfaces.find { |object| object.input_object.equal?(@input_object.fields[4]) }
      end
      return(parent)
    end


##### Begin override methods for the entity #####


    # Error checks, finalization, or cleanup needed after the entity is drawn.
    def confirm_entity
      return(super)

      # Check for overlapping sub surfaces in the same zone.
      # Check for sub surfaces not on their base surface.
      # Check for more than 4 vertices.  subdivide if necessary.
      # if check really fails, might be able to call Sketchup.undo.


      #points = @entity.polygon.reduce.points
      #if (points.length > 4)
      
        #puts "Oops!  Too many vertices!"
        
        # Draw an edge from the first vertex to the 4th
        
        #@entity.parent.entities.add_line(points[0], points[3])
        
        #Sketchup.undo  # oh yeah can't undo because observer has already assigned some things.
        #return(false)
      #end
    end


    # Returns the parent drawing interface according to the entity.
    def parent_from_entity
      if (valid_entity?)
        if (base_face = DrawingUtils.detect_base_face(@entity))
          return(base_face.drawing_interface)
        else
          return(super)  # Return the zone interface
        end
      else
        return(super)  # Return the zone interface
      end
    end


##### Begin override methods for the interface #####


    def surface_type
      return(@input_object.fields[2])
    end


##### Begin new methods for the interface #####


    # Check if the sub surface should be a window or a door.
    def default_surface_type
      if (@entity.normal.parallel?(Geom::Vector3d.new(0,0,1)))
        # Horizontal surfaces should never have doors by default (but the user can change it later).
        surface_type = "Window"

      else
        # Calculate midpoints of each line segment that make up the sub face
        # NOTE:  This is probably very inefficient, but still should be fast enough.
        midpoints = []
        for i in 0...@entity.outer_polygon.points.length
          this_point = @entity.outer_polygon.points[i]
          if (i == @entity.outer_polygon.points.length - 1)
            next_point = @entity.outer_polygon.points.first
          else
            next_point = @entity.outer_polygon.points[i + 1]
          end
          midpoints << Geom.linear_combination(0.5, this_point, 0.5, next_point) 
        end

        # Find midpoint that is lowest in the z-direction
        lowest_midpoint = midpoints[0]
        for this_point in midpoints
          if (this_point.z < lowest_midpoint.z)
            lowest_midpoint = this_point
          end
        end

        # Check if the lowest midpoint is inside the base surface
        update_parent_from_entity
        if (@parent.class == BaseSurface)
          if (Geom.point_in_polygon(lowest_midpoint, @parent.entity.outer_polygon, true))
            surface_type = "Window"
          else
            surface_type = "Door"
          end
        else
          surface_type = "Window"
        end
      end

      return(surface_type)
    end
    
    def exterior?
      return (@input_object.fields[5].nil? or @input_object.fields[5].to_s.empty?)
    end

    def default_construction    
      case (default_surface_type.upcase)
      when "WINDOW", "GLASSDOOR", "TUBULARDAYLIGHTDOME", "TUBULARDAYLIGHTDIFFUSER"
        if exterior?
          construction_name = Plugin.model_manager.construction_manager.default_window_ext
        else
          construction_name = Plugin.model_manager.construction_manager.default_window_int
        end
      when "DOOR"
        if exterior?
          construction_name = Plugin.model_manager.construction_manager.default_door_ext
        else
          construction_name = Plugin.model_manager.construction_manager.default_door_int
        end
      end
      
      return(construction_name)
    end
    
    def in_selection?(selection)
      return (selection.contains?(@entity) or selection.contains?(@parent.entity) or (not @parent.parent.nil? and selection.contains?(@parent.parent.entity)))
    end
    
    def multiplier
      value = @input_object.fields[9].to_i
      if (value > 0)
        return(value)
      else
        return(1)
      end
    end

    def area
      return(self.unit_area * self.multiplier)
    end
    
    def name
      return @input_object.fields[1]
    end

    def unit_area
      if (valid_entity? and not deleted?)
        return(@entity.area)
      else
        return(0.0)
      end
    end


    def paint_surface_type
      if (valid_entity?)
        if (surface_type.upcase == "DOOR")
          @entity.material = Plugin.model_manager.construction_manager.door_ext
          @entity.back_material = Plugin.model_manager.construction_manager.door_int
        else
          @entity.material = Plugin.model_manager.construction_manager.window_ext
          @entity.back_material = Plugin.model_manager.construction_manager.window_int
        end
      end
    end

    def paint_boundary
      if (valid_entity?)
        if exterior?
          @entity.material = Plugin.model_manager.construction_manager.subext_ext
          @entity.back_material = Plugin.model_manager.construction_manager.subext_int
        else
          @entity.material = Plugin.model_manager.construction_manager.subint_ext
          @entity.back_material = Plugin.model_manager.construction_manager.subint_int
        end
      end
    end
    
    # match this sub surface to another sub surface
    def set_other_side_sub_surface(other)
      @input_object.fields[5] = other.name
      @input_object.fields[3] = default_construction # after making interior
      #if render set to by boundary then change materials to surface
          if (Plugin.model_manager.rendering_mode == 2)
              #apply material to front and back face
              @entity.material = Plugin.model_manager.construction_manager.subint_ext
              @entity.back_material = Plugin.model_manager.construction_manager.subint_int
          else
          end

    end
    
    # unmatch this sub surface with any other sub surface
    def unset_other_side_sub_surface
      @input_object.fields[5] = ""
      @input_object.fields[3] = default_construction # after making exterior
      #if render set to by boundary then change materials to surface
          if (Plugin.model_manager.rendering_mode == 2)
              #apply material to front and back face
              @entity.material = Plugin.model_manager.construction_manager.outdoorssunwind_ext
              @entity.back_material = Plugin.model_manager.construction_manager.outdoorssunwind_int
          else
          end
    end

  end

end
