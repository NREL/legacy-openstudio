# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/interfaces/DrawingInterface")


module LegacyOpenStudio

  class SurfaceGeometry < DrawingInterface

    def create_input_object
      @input_object = InputObject.new("GLOBALGEOMETRYRULES")
      @input_object.fields[1] = "UpperLeftCorner"
      @input_object.fields[2] = "Counterclockwise"
      @input_object.fields[3] = "Absolute"

      super
    end


    def parent_from_input_object
      return(Plugin.model_manager.model_interface)
    end


    # Drawing interfaces that don't correspond directly to a SketchUp entity (SurfaceGeometry, Building)
    # should return false here.
    def valid_entity?
      return(false)
    end


    # Drawing interfaces that don't correspond directly to a SketchUp entity (SurfaceGeometry, Building)
    # should return false here.
    def check_entity
      return(false) 
    end


    # Checks needed before the entity can be drawn.
    # There should be no references to @entity in here.
    # Checks the input object for errors and tries to fix them before drawing the entity.
    # Returns false if errors are beyond repair.
    def check_input_object
      if (super)

        # Check "First Vertex" field
        if (@input_object.fields[1].nil?)
          puts "SurfaceGeometry.first_vertex:  missing input for starting vertex"
          @input_object.fields[1] = "UpperLeftCorner"
        else
          case(@input_object.fields[1].upcase)

          when "UPPERLEFTCORNER", "ULC"
            @input_object.fields[1] = "UpperLeftCorner"

          when "LOWERLEFTCORNER", "LLC"
            @input_object.fields[1] = "LowerLeftCorner"

          when "UPPERRIGHTCORNER", "URC"
            @input_object.fields[1] = "UpperRightCorner"

          when "LOWERRIGHTCORNER", "LRC"
            @input_object.fields[1] = "LowerRightCorner"

          else
            puts "SurfaceGeometry.vertex_order:  bad input for starting vertex"
            Plugin.model_manager.add_error("Error:  Bad input for starting vertex in GlobalGeometryRules object.\n")
            Plugin.model_manager.add_error("Starting vertex order has been reset to UpperLeftCorner.\n\n")

            @input_object.fields[1] = "UpperLeftCorner"
          end
        end

        # Check "Vertex Order" field
        if (@input_object.fields[2].nil?)
          puts "SurfaceGeometry.vertex_order:  missing input for vertex order"
          @input_object.fields[2] = "Counterclockwise"
        else
          case(@input_object.fields[2].upcase)

          when "CLOCKWISE", "CW"
            @input_object.fields[2] = "Clockwise"

          when "COUNTERCLOCKWISE", "CCW"
            @input_object.fields[2] = "Counterclockwise"

          else
            puts "SurfaceGeometry.vertex_order:  bad input for vertex order"
            Plugin.model_manager.add_error("Error:  Bad input for vertex order in GlobalGeometryRules object.\n")
            Plugin.model_manager.add_error("Vertex order has been reset to Counterclockwise.\n\n")

            @input_object.fields[2] = "Counterclockwise"
          end
        end

        # Check "Coordinate System" field
        if (@input_object.fields[3].nil?)
          puts "SurfaceGeometry.coordinate_system:  missing input for coordinate system"
          @input_object.fields[3] = "World"
        else
          case(@input_object.fields[3].upcase)

          when "RELATIVE"
            @input_object.fields[3] = "Relative"

          when "WCS", "WORLDCOORDINATESYSTEM", "WORLD", "ABSOLUTE"
            @input_object.fields[3] = "Absolute"

          else
            puts "SurfaceGeometry.coordinate_system:  bad input for coordinate system"
            Plugin.model_manager.add_error("Error:  Bad input for coordinate system in GlobalGeometryRules object.\n")
            Plugin.model_manager.add_error("Coordinate system has been reset to Absolute.\n\n")

            @input_object.fields[3] = "Absolute"
          end
        end

        return(true)
      else
        return(false)
      end      
    end


    def on_change_input_object
      # Recalculates all vertex coordinates based on current SurfaceGeometry rules (coord sys, vertex order, first vertex)
      Plugin.model_manager.all_surfaces.each { |drawing_interface| drawing_interface.update_input_object }
      Plugin.model_manager.output_illuminance_maps.each { |drawing_interface| drawing_interface.update_input_object }
      Plugin.model_manager.daylighting_controls.each { |drawing_interface| drawing_interface.update_input_object }

      Plugin.dialog_manager.update(ObjectInfoInterface)
    end


    # Not used, but could recalculate and redraw all geometry in the new coordinate system.
    def update_entity
    end


  end

end
