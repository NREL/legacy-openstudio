# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/interfaces/Surface")
require("legacy_openstudio/lib/inputfile/InputObject")
require("legacy_openstudio/lib/dialogs/ProgressDialog")


module LegacyOpenStudio

  class BaseSurface < Surface

    def initialize
      super
      @first_vertex_field = 11
    end


##### Begin override methods for the input object #####


    def create_input_object
      @input_object = InputObject.new("BUILDINGSURFACE:DETAILED")
      @input_object.fields[1] = Plugin.model_manager.input_file.new_unique_object_name
      @input_object.fields[2] = default_surface_type   # infer_surface_type
      @input_object.fields[3] = ""
      @input_object.fields[4] = ""  # Zone

      if (@input_object.fields[2] == "Floor")
        @input_object.fields[5] = "Ground"
        @input_object.fields[6] = ""
        @input_object.fields[7] = "NoSun"
        @input_object.fields[8] = "NoWind"
      else
        @input_object.fields[5] = "Outdoors"
        @input_object.fields[6] = ""
        @input_object.fields[7] = "SunExposed"
        @input_object.fields[8] = "WindExposed"
      end
      
      @input_object.fields[3] = default_construction # do after setting boundary conditions

      @input_object.fields[9] = ""
      @input_object.fields[12] = 0  # kludge to make fields list long enough for call below

      super
    end

    def check_input_object
      if (super)
        # Check for upside-down floors, roofs, or ceilings
        dot_product = input_object_polygon.normal % Geom::Vector3d.new(0, 0, 1)
        if (surface_type.upcase == "FLOOR")
          if ((Plugin.model_manager.surface_geometry.input_object.fields[2].upcase == "COUNTERCLOCKWISE" and dot_product > 0.000001))  \
            or ((Plugin.model_manager.surface_geometry.input_object.fields[2].upcase == "CLOCKWISE" and dot_product < -0.000001))

            Plugin.model_manager.add_error("Warning:  " + @input_object.key + "\n")
            Plugin.model_manager.add_error("This Floor surface is upside-down.\nIt has been automatically fixed.\n\n")

            # Better to add a 'reverse!' method to Surface.
            self.input_object_polygon = self.input_object_polygon.reverse
          end
        elsif (surface_type.upcase == "ROOF" or surface_type.upcase == "CEILING")
          if ((Plugin.model_manager.surface_geometry.input_object.fields[2].upcase == "COUNTERCLOCKWISE" and dot_product < -0.000001))  \
            or ((Plugin.model_manager.surface_geometry.input_object.fields[2].upcase == "CLOCKWISE" and dot_product > 0.000001))

            Plugin.model_manager.add_error("Warning:  " + @input_object.key + "\n")
            Plugin.model_manager.add_error("This Roof or Ceiling surface is upside-down.\nIt has been automatically fixed.\n\n")

            # Better to add a 'reverse!' method to Surface.
            self.input_object_polygon = self.input_object_polygon.reverse
          end
        end

        # Look up the Zone drawing interface (might fail if the reference is bad)
        if (not parent_from_input_object)
          Plugin.model_manager.add_error("Warning:  " + @input_object.key + "\n")
          Plugin.model_manager.add_error("The zone referenced by this base surface does not exist.\n")
          Plugin.model_manager.add_error("A new zone object has been automatically created for this surface.\n\n")  # Done in create_entity
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
        @input_object.fields[4] = @parent.input_object  # Parent should already have been updated.

        # This is some extra (redundant?) error checking that was added because Zone objects were disappearing.

        # Check if Zone object is still in the input file objects
        if (not Plugin.model_manager.input_file.object_exists?(@parent.input_object))
          UI.messagebox("BaseSurface.update_input_object:  Zone drawing interface is missing from input file objects!")
        end

        # Check if Zone object was deleted
        if (@parent.deleted?)
          UI.messagebox("BaseSurface.update_input_object:  Zone drawing interface is a deleted object!")
        end

      end

      # Check for coincident surfaces?

    end


    # Returns the parent drawing interface according to the input object.
    def parent_from_input_object
      parent = nil
      if (@input_object)
        parent = Plugin.model_manager.zones.find { |object| object.input_object.equal?(@input_object.fields[4]) }
      end
      return(parent)
    end


##### Begin override methods for the entity #####


    # Error checks, finalization, or cleanup needed after the entity is drawn.
    def confirm_entity
      super

      # Check for overlapping base surfaces in the same zone; could be completely coincident,e.g., user copied a surface then forgot to change the z coords.
      # Or should this be checked before drawing?
      # SU7 automatically divides the surfaces.  This will always end up creating extra surfaces.  Don't know which parent the child will take after...
    end


##### Begin override methods for the interface #####


    def surface_type
      return(@input_object.fields[2])
    end


    def paint_surface_type
      if (valid_entity?)
        if (surface_type.upcase == "FLOOR")
          @entity.material = Plugin.model_manager.construction_manager.floor_ext
          @entity.back_material = Plugin.model_manager.construction_manager.floor_int
        elsif (surface_type.upcase == "ROOF" or surface_type.upcase == "CEILING")
          @entity.material = Plugin.model_manager.construction_manager.roof_ext
          @entity.back_material = Plugin.model_manager.construction_manager.roof_int
        elsif (surface_type.upcase == "WALL")
          @entity.material = Plugin.model_manager.construction_manager.wall_ext
          @entity.back_material = Plugin.model_manager.construction_manager.wall_int
        end
      end
    end

    def boundary
      # field 7 is sun, 8 is wind
      return(@input_object.fields[5])
    end

    def sun
      return(@input_object.fields[7])
    end

    def wind
      return(@input_object.fields[8])
    end


    def paint_boundary
      if (valid_entity?)
        if (boundary.upcase == "SURFACE")
          @entity.material = Plugin.model_manager.construction_manager.surface_ext
          @entity.back_material = Plugin.model_manager.construction_manager.surface_int
        elsif (boundary.upcase == "ADIABATIC")
          @entity.material = Plugin.model_manager.construction_manager.adiabatic_ext
          @entity.back_material = Plugin.model_manager.construction_manager.adiabatic_int
        elsif (boundary.upcase == "ZONE")
          @entity.material = Plugin.model_manager.construction_manager.zone_ext
          @entity.back_material = Plugin.model_manager.construction_manager.zone_int
        elsif (boundary.upcase == "OUTDOORS")
          # add if statements to break into nosunnowind, nosun, nowind, or both sunwind
               if (sun.upcase == "SUNEXPOSED")
                  if (wind.upcase == "WINDEXPOSED")
                    @entity.material = Plugin.model_manager.construction_manager.outdoorssunwind_ext
                    @entity.back_material = Plugin.model_manager.construction_manager.outdoorssunwind_int
                   else
                    @entity.material = Plugin.model_manager.construction_manager.outdoorssun_ext
                    @entity.back_material = Plugin.model_manager.construction_manager.outdoorssun_int
                   end
               else
                  if (wind.upcase == "WINDEXPOSED")
                    @entity.material = Plugin.model_manager.construction_manager.outdoorswind_ext
                    @entity.back_material = Plugin.model_manager.construction_manager.outdoorswind_int
                  else
                    @entity.material = Plugin.model_manager.construction_manager.outdoors_ext
                    @entity.back_material = Plugin.model_manager.construction_manager.outdoors_int
                  end
               end
        elsif (boundary.upcase == "GROUND")
          @entity.material = Plugin.model_manager.construction_manager.ground_ext
          @entity.back_material = Plugin.model_manager.construction_manager.ground_int
        elsif (boundary.upcase == "GROUNDFCFACTORMETHOD")
          @entity.material = Plugin.model_manager.construction_manager.groundfcfactormethod_ext
          @entity.back_material = Plugin.model_manager.construction_manager.groundfcfactormethod_int
        elsif (boundary.upcase == "GROUNDSLABPREPROCESSORAVERAGE")
          @entity.material = Plugin.model_manager.construction_manager.groundslabpreprocessoraverage_ext
          @entity.back_material = Plugin.model_manager.construction_manager.groundslabpreprocessoraverage_int
        elsif (boundary.upcase == "GROUNDSLABPREPROCESSORCORE")
          @entity.material = Plugin.model_manager.construction_manager.groundslabpreprocessorcore_ext
          @entity.back_material = Plugin.model_manager.construction_manager.groundslabpreprocessorcore_int
        elsif (boundary.upcase == "GROUNDSLABPREPROCESSORPERIMETER")
          @entity.material = Plugin.model_manager.construction_manager.groundslabpreprocessorperimeter_ext
          @entity.back_material = Plugin.model_manager.construction_manager.groundslabpreprocessorperimeter_int
        elsif (boundary.upcase == "GROUNDBASEMENTPREPROCESSORAVERAGEWALL")
          @entity.material = Plugin.model_manager.construction_manager.groundbasementpreprocessoraveragewall_ext
          @entity.back_material = Plugin.model_manager.construction_manager.groundbasementpreprocessoraveragewall_int
        elsif (boundary.upcase == "GROUNDBASEMENTPREPROCESSORAVERAGEFLOOR")
          @entity.material = Plugin.model_manager.construction_manager.groundbasementpreprocessoraveragefloor_ext
          @entity.back_material = Plugin.model_manager.construction_manager.groundbasementpreprocessoraveragefloor_int
        elsif (boundary.upcase == "GROUNDBASEMENTPREPROCESSORUPPERWALL")
          @entity.material = Plugin.model_manager.construction_manager.groundbasementpreprocessorupperwall_ext
          @entity.back_material = Plugin.model_manager.construction_manager.groundbasementpreprocessorupperwall_int
        elsif (boundary.upcase == "GROUNDBASEMENTPREPROCESSORLOWERWALL")
          @entity.material = Plugin.model_manager.construction_manager.groundbasementpreprocessorlowerwall_ext
          @entity.back_material = Plugin.model_manager.construction_manager.groundbasementpreprocessorlowerwall_int
        elsif (boundary.upcase == "OTHERSIDECOEFFICIENTS")
          @entity.material = Plugin.model_manager.construction_manager.othersidecoefficients_ext
          @entity.back_material = Plugin.model_manager.construction_manager.othersidecoefficients_int
        elsif (boundary.upcase == "OTHERSIDECONDITIONSMODEL")
          @entity.material = Plugin.model_manager.construction_manager.othersideconditionsmodel_ext
          @entity.back_material = Plugin.model_manager.construction_manager.othersideconditionsmodel_int
        end
      end
    end

    # Returns the polygon of the face in absolute coordinates.
    # This is overridden from the Surface class to subtract the vertices of any sub surfaces.
    # This can probably be optimized quite a bit.
    def face_polygon
      if (valid_entity?)
        # Get list of children based on actual faces that share vertices with the base face.
        # This is more dynamic than looking at @children which may not be up-to-date yet.
        child_faces = []
        for face in group_entity.entities
          if (face.class == Sketchup::Face and @entity == DrawingUtils.detect_base_face(face))
            #puts "found child face->" + face.to_s
            child_faces << face
          end
        end

        reduced_polygon = Geom::Polygon.new(@entity.absolute_polygon.outer_loop.reduce)  # Removes colinear points
        new_points = []
        for point in reduced_polygon.points

          found = false
          for child in child_faces
            for sub_point in child.absolute_polygon.points
              if (point == sub_point)
                #puts "sub face vertex subtracted"
                found = true
                break
              end
            end

            if (found)
              break
            end
          end

          if (not found)
            new_points << point
          end
        end

        new_points = apply_surface_geometry(new_points)

        return(Geom::Polygon.new(new_points))
      else
        puts "BaseSurface.face_polygon:  entity not valid"
        return(nil)
      end
    end


##### Begin new methods for the interface #####


    def default_surface_type
      # There are sometimes  tolerance issues here.
      # For example, a wall can give an outward normal of (1.0, 0.0, 1.59571514277929e-016)
      dot_product = @entity.normal % Geom::Vector3d.new(0, 0, 1)
      if (dot_product > 0.000001)
        surface_type = "Roof"
      elsif (dot_product == -1.0)
        surface_type = "Floor"
      else
        surface_type = "Wall"
      end
      return(surface_type)
    end
    
    def exterior?
      return (@input_object.fields[5] == "Ground" or @input_object.fields[5] == "Outdoors")
    end

    def default_construction
      case (default_surface_type.upcase)
      when "FLOOR"
        if exterior?
          construction_name = Plugin.model_manager.construction_manager.default_floor_ext
        else
          construction_name = Plugin.model_manager.construction_manager.default_floor_int
        end
      when "WALL"
        if exterior?
          construction_name = Plugin.model_manager.construction_manager.default_wall_ext
        else
          construction_name = Plugin.model_manager.construction_manager.default_wall_int
        end      
      when "ROOF", "CEILING"
         if exterior?
          construction_name = Plugin.model_manager.construction_manager.default_roof_ext
        else
          construction_name = Plugin.model_manager.construction_manager.default_roof_int
        end     
      end
      
      return(construction_name)
    end
    
    def in_selection?(selection)
      return (selection.contains?(@entity) or selection.contains?(@parent.entity))
    end
    
    def name
      @input_object.fields[1]
    end


    def net_area
      return(self.area)
    end
    

    def gross_area
      area_sum = self.area
      for child in @children
        if (child.class == SubSurface)
          area_sum += child.area
        end
      end
      return(area_sum)
    end


    def glazing_area
      area = 0.0 
      for child in @children
        if (child.class == SubSurface and (child.surface_type.upcase == "WINDOW" or child.surface_type.upcase == "GLASSDOOR"))
          area += child.area
        end
      end
      return(area)
    end


    def percent_glazing
      if (self.gross_area > 0.0)
        return(100.0 * self.glazing_area / self.gross_area)
      else
        return(0.0)
      end
    end


    def sub_surface_count
      count = 0
      @children.each { |child| count += 1 if (child.class == SubSurface) }
      return(count)
    end
    
    
    # match this base surface to another base surface
    def set_other_side_surface(other)
      if (@input_object.fields[2].upcase == "ROOF")
        @input_object.fields[2] = "Ceiling"
      end
      @input_object.fields[5] = 'Surface'
      @input_object.fields[6] = other.name
      @input_object.fields[7] = "NoSun"
      @input_object.fields[8] = "NoWind"
      @input_object.fields[3] = default_construction # do after making interior
      #if render set to by boundary then change materials to surface
          if (Plugin.model_manager.rendering_mode == 2)
              #apply material to front and back face
              @entity.material = Plugin.model_manager.construction_manager.surface_ext
              @entity.back_material = Plugin.model_manager.construction_manager.surface_int
          else
          end
      
    end
    
    # set this base surface to reference no other base surface
    def unset_other_side_surface
    
      if (@input_object.fields[2].upcase == "CEILING")
        @input_object.fields[2] = "Roof"
      end
      
      if (@input_object.fields[2] == "Floor")
        @input_object.fields[5] = "Ground"
        @input_object.fields[6] = ""
        @input_object.fields[7] = "NoSun"
        @input_object.fields[8] = "NoWind"
      #if render set to by boundary then change materials to surface
          if (Plugin.model_manager.rendering_mode == 2)
              #apply material to front and back face
              @entity.material = Plugin.model_manager.construction_manager.ground_ext
              @entity.back_material = Plugin.model_manager.construction_manager.ground_int
          else
          end
      else
        @input_object.fields[5] = "Outdoors"
        @input_object.fields[6] = ""
        @input_object.fields[7] = "SunExposed"
        @input_object.fields[8] = "WindExposed"
      #if render set to by boundary then change materials to surface
          if (Plugin.model_manager.rendering_mode == 2)
              #apply material to front and back face
              @entity.material = Plugin.model_manager.construction_manager.outdoorssunwind_ext
              @entity.back_material = Plugin.model_manager.construction_manager.outdoorssunwind_int
          else
          end
      end   

      @input_object.fields[3] = default_construction # do after making exterior

    end    

  end

end
