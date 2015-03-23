# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.


module LegacyOpenStudio

  module SimpleGeometry

    NO_CHANGE = 0
    REL_TO_ABS = 1
    ABS_TO_REL = 2

    LEFT_SIDE = 0
    RIGHT_SIDE = 1

    # Convert simple rectangular geometry surfaces to detailed ones.
    # Because of dependencies, surfaces must be processed in this order: shading, sub surfaces, base surfaces.
    def SimpleGeometry.convert_to_detailed(input_file)

      # Reconcile the coordinate systems for simple geometry.
      # If the normal system and the simple one are different, the simple objects
      # must be transformed to the expected coordinate system.
      # NOTE:  GlobalGeometryRules has not been parsed into a SurfaceGeometry object yet.
      if (surface_geometry = input_file.find_objects_by_class_name("GlobalGeometryRules").to_a.first)

        case (surface_geometry.fields[3].upcase)
        when "ABSOLUTE", "WORLD", "WORLDCOORDINATESYSTEM", "WCS"
          normal_coord_sys = "Absolute"
        else
          normal_coord_sys = "Relative"
        end

        if (surface_geometry.fields[5])
          case (surface_geometry.fields[5].upcase)
          when "ABSOLUTE", "WORLD", "WORLDCOORDINATESYSTEM", "WCS"
            simple_coord_sys = "Absolute"
          else
            simple_coord_sys = "Relative"
          end
        else
          simple_coord_sys = "Relative"  # Default
        end

        if (simple_coord_sys == "Relative" and normal_coord_sys == "Absolute")
          coord_change = REL_TO_ABS
        elsif (simple_coord_sys == "Absolute" and normal_coord_sys == "Relative")
          coord_change = ABS_TO_REL
        else
          coord_change = NO_CHANGE
        end

      else
        # OpenStudio defaults normal to Absolute; EnergyPlus defaults simple to Relative.
        coord_change = REL_TO_ABS
      end


      # Get the building transformation.
      if (building = input_file.find_objects_by_class_name("Building").to_a.first)
        origin = Geom::Point3d.new(0, 0, 0)
        z_axis = Geom::Vector3d.new(0, 0, 1)
        rotation_angle = (-building.fields[2].to_f).degrees
        building_rotation = Geom::Transformation.rotation(origin, z_axis, rotation_angle)
      else
        building_rotation = Geom::Transformation.new  # Identity transformation
      end


      # Loop through all objects and handle shading surfaces first (so that base surface info is preserved)
      for input_object in input_file.objects
        case (input_object.class_definition.name)

        when "Shading:Site"
          puts "converting:  " + input_object.key
          old_fields = input_object.fields.dup
          vertices = SimpleGeometry.calc_vertices(input_object, coord_change, building_rotation)
          input_object.class_definition = Plugin.data_dictionary.get_class_def("Shading:Site:Detailed")
          input_object.fields[0] = "Shading:Site:Detailed"
          input_object.fields[1] = old_fields[1]
          input_object.fields[2] = ""
          input_object.fields[3] = "4"
          input_object.fields[4..15] = vertices
          input_object.context = nil
          input_object.format_context
          input_file.modified = true

        when "Shading:Building"
          puts "converting:  " + input_object.key
          old_fields = input_object.fields.dup
          vertices = SimpleGeometry.calc_vertices(input_object, coord_change, building_rotation)
          input_object.class_definition = Plugin.data_dictionary.get_class_def("Shading:Building:Detailed")
          input_object.fields[0] = "Shading:Building:Detailed"
          input_object.fields[1] = old_fields[1]
          input_object.fields[2] = ""
          input_object.fields[3] = "4"
          input_object.fields[4..15] = vertices
          input_object.context = nil
          input_object.format_context
          input_file.modified = true

        when "Shading:Overhang", "Shading:Overhang:Projection"
          puts "converting:  " + input_object.key
          old_fields = input_object.fields.dup
          vertices = SimpleGeometry.calc_vertices(input_object, coord_change, building_rotation)
          input_object.class_definition = Plugin.data_dictionary.get_class_def("Shading:Zone:Detailed")
          input_object.fields[0] = "Shading:Zone:Detailed"
          input_object.fields[1] = old_fields[1]
          input_object.fields[2] = old_fields[2].fields[3]  # Get base surface...no error trapping
          input_object.fields[3] = ""
          input_object.fields[4] = "4"
          input_object.fields[5..16] = vertices
          input_object.context = nil
          input_object.format_context
          input_file.modified = true

        when "Shading:Fin", "Shading:Fin:Projection"
          puts "converting:  " + input_object.key
          old_fields = input_object.fields.dup

          vertices_left = SimpleGeometry.calc_vertices(input_object, coord_change, building_rotation, LEFT_SIDE)
          new_input_object = InputObject.new("Shading:Zone:Detailed")
          new_input_object.fields[0] = "Shading:Zone:Detailed"
          new_input_object.fields[1] = old_fields[1] + " L"
          new_input_object.fields[2] = old_fields[2].fields[3]  # Get base surface...no error trapping
          new_input_object.fields[3] = ""
          new_input_object.fields[4] = "4"
          new_input_object.fields[5..16] = vertices_left
          new_input_object.context = nil
          new_input_object.format_context
          Plugin.model_manager.input_file.add_object(new_input_object)

          # Hack the original input object to move the second (right hand side) set of fields up.
          input_object.fields[3..7] = input_object.fields[8..12]

          vertices_right = SimpleGeometry.calc_vertices(input_object, coord_change, building_rotation, RIGHT_SIDE)

          input_object.class_definition = Plugin.data_dictionary.get_class_def("Shading:Zone:Detailed")
          input_object.fields[0] = "Shading:Zone:Detailed"
          input_object.fields[1] = old_fields[1] + " R"
          input_object.fields[2] = old_fields[2].fields[3]  # Get base surface...no error trapping
          input_object.fields[3] = ""
          input_object.fields[4] = "4"
          input_object.fields[5..16] = vertices_right
          input_object.context = nil
          input_object.format_context
          input_file.modified = true

        end
      end


      # Loop through all objects and handle sub surfaces first (so that base surface info is preserved)
      for input_object in input_file.objects
        case (input_object.class_definition.name)

        when "Window"
          puts "converting:  " + input_object.key
          
          old_fields = input_object.fields.dup
          vertices = SimpleGeometry.calc_vertices(input_object, coord_change, building_rotation)
          input_object.class_definition = Plugin.data_dictionary.get_class_def("FenestrationSurface:Detailed")
          input_object.fields[0] = "FenestrationSurface:Detailed"
          input_object.fields[1] = old_fields[1]
          input_object.fields[2] = "Window"
          input_object.fields[3..4] = old_fields[2..3]
          input_object.fields[5] = ""
          input_object.fields[6] = ""
          input_object.fields[7..9] = old_fields[4..6]
          input_object.fields[10] = "4"
          input_object.fields[11..22] = vertices
          input_object.context = nil
          input_object.format_context
          input_file.modified = true

        when "Door"
          puts "converting:  " + input_object.key
          old_fields = input_object.fields.dup
          vertices = SimpleGeometry.calc_vertices(input_object, coord_change, building_rotation)
          input_object.class_definition = Plugin.data_dictionary.get_class_def("FenestrationSurface:Detailed")
          input_object.fields[0] = "FenestrationSurface:Detailed"
          input_object.fields[1] = old_fields[1]
          input_object.fields[2] = "Door"
          input_object.fields[3..4] = old_fields[2..3]
          input_object.fields[5] = ""
          input_object.fields[6] = ""
          input_object.fields[7] = ""
          input_object.fields[8] = ""
          input_object.fields[9] = old_fields[4]
          input_object.fields[10] = "4"
          input_object.fields[11..22] = vertices
          input_object.context = nil
          input_object.format_context
          input_file.modified = true

        when "GlazedDoor"
          puts "converting:  " + input_object.key
          old_fields = input_object.fields.dup
          vertices = SimpleGeometry.calc_vertices(input_object, coord_change, building_rotation)
          input_object.class_definition = Plugin.data_dictionary.get_class_def("FenestrationSurface:Detailed")
          input_object.fields[0] = "FenestrationSurface:Detailed"
          input_object.fields[1] = old_fields[1]
          input_object.fields[2] = "GlassDoor"
          input_object.fields[3..4] = old_fields[2..3]
          input_object.fields[5] = ""
          input_object.fields[6] = ""
          input_object.fields[7] = ""
          input_object.fields[8] = ""
          input_object.fields[9] = old_fields[4]
          input_object.fields[10] = "4"
          input_object.fields[11..22] = vertices
          input_object.context = nil
          input_object.format_context
          input_file.modified = true

        when "Window:Interzone"
          puts "converting:  " + input_object.key
          old_fields = input_object.fields.dup
          vertices = SimpleGeometry.calc_vertices(input_object, coord_change, building_rotation)
          input_object.class_definition = Plugin.data_dictionary.get_class_def("FenestrationSurface:Detailed")
          input_object.fields[0] = "FenestrationSurface:Detailed"
          input_object.fields[1] = old_fields[1]
          input_object.fields[2] = "Window"
          input_object.fields[3..5] = old_fields[2..4]
          input_object.fields[6] = ""
          input_object.fields[7] = ""
          input_object.fields[8] = ""
          input_object.fields[9] = old_fields[5]
          input_object.fields[10] = "4"
          input_object.fields[11..22] = vertices
          input_object.context = nil
          input_object.format_context
          input_file.modified = true

        when "Door:Interzone"
          puts "converting:  " + input_object.key
          old_fields = input_object.fields.dup
          vertices = SimpleGeometry.calc_vertices(input_object, coord_change, building_rotation)
          input_object.class_definition = Plugin.data_dictionary.get_class_def("FenestrationSurface:Detailed")
          input_object.fields[0] = "FenestrationSurface:Detailed"
          input_object.fields[1] = old_fields[1]
          input_object.fields[2] = "Door"
          input_object.fields[3..5] = old_fields[2..4]
          input_object.fields[6] = ""
          input_object.fields[7] = ""
          input_object.fields[8] = ""
          input_object.fields[9] = old_fields[5]
          input_object.fields[10] = "4"
          input_object.fields[11..22] = vertices
          input_object.context = nil
          input_object.format_context
          input_file.modified = true

        when "GlazedDoor:Interzone"
          puts "converting:  " + input_object.key
          old_fields = input_object.fields.dup
          vertices = SimpleGeometry.calc_vertices(input_object, coord_change, building_rotation)
          input_object.class_definition = Plugin.data_dictionary.get_class_def("FenestrationSurface:Detailed")
          input_object.fields[0] = "FenestrationSurface:Detailed"
          input_object.fields[1] = old_fields[1]
          input_object.fields[2] = "GlassDoor"
          input_object.fields[3..5] = old_fields[2..4]
          input_object.fields[6] = ""
          input_object.fields[7] = ""
          input_object.fields[8] = ""
          input_object.fields[9] = old_fields[5]
          input_object.fields[10] = "4"
          input_object.fields[11..22] = vertices
          input_object.context = nil
          input_object.format_context
          input_file.modified = true

        end
      end


      # Loop through all objects and handle base surfaces.
      for input_object in input_file.objects
        case (input_object.class_definition.name)

        when "Wall:Detailed"
          puts "converting:  " + input_object.key
          old_fields = input_object.fields.dup
          input_object.class_definition = Plugin.data_dictionary.get_class_def("BuildingSurface:Detailed")
          input_object.fields[0] = "BuildingSurface:Detailed"
          input_object.fields[1] = old_fields[1]
          input_object.fields[2] = "Wall"
          input_object.fields[3..-1] = old_fields[2..-1]
          input_object.context = nil
          input_object.format_context
          input_file.modified = true

        when "RoofCeiling:Detailed"
          puts "converting:  " + input_object.key
          old_fields = input_object.fields.dup
          input_object.class_definition = Plugin.data_dictionary.get_class_def("BuildingSurface:Detailed")
          input_object.fields[0] = "BuildingSurface:Detailed"
          input_object.fields[1] = old_fields[1]
          input_object.fields[2] = "Roof"
          input_object.fields[3..-1] = old_fields[2..-1]
          input_object.context = nil
          input_object.format_context
          input_file.modified = true

        when "Floor:Detailed"
          puts "converting:  " + input_object.key
          old_fields = input_object.fields.dup
          input_object.class_definition = Plugin.data_dictionary.get_class_def("BuildingSurface:Detailed")
          input_object.fields[0] = "BuildingSurface:Detailed"
          input_object.fields[1] = old_fields[1]
          input_object.fields[2] = "Floor"
          input_object.fields[3..-1] = old_fields[2..-1]
          input_object.context = nil
          input_object.format_context
          input_file.modified = true

        when "Wall:Exterior"
          puts "converting:  " + input_object.key
          old_fields = input_object.fields.dup
          vertices = SimpleGeometry.calc_vertices(input_object, coord_change, building_rotation)
          input_object.class_definition = Plugin.data_dictionary.get_class_def("BuildingSurface:Detailed")
          input_object.fields[0] = "BuildingSurface:Detailed"
          input_object.fields[1] = old_fields[1]
          input_object.fields[2] = "Wall"
          input_object.fields[3..4] = old_fields[2..3]
          input_object.fields[5] = "Outdoors"
          input_object.fields[6] = ""
          input_object.fields[7] = "SunExposed"
          input_object.fields[8] = "WindExposed"
          input_object.fields[9] = ""
          input_object.fields[10] = "4"
          input_object.fields[11..22] = vertices
          input_object.context = nil
          input_object.format_context
          input_file.modified = true

        when "Wall:Adiabatic"
          puts "converting:  " + input_object.key
          old_fields = input_object.fields.dup
          vertices = SimpleGeometry.calc_vertices(input_object, coord_change, building_rotation)
          input_object.class_definition = Plugin.data_dictionary.get_class_def("BuildingSurface:Detailed")
          input_object.fields[0] = "BuildingSurface:Detailed"
          input_object.fields[1] = old_fields[1]
          input_object.fields[2] = "Wall"
          input_object.fields[3..4] = old_fields[2..3]
          input_object.fields[5] = "Adiabatic"
          input_object.fields[6] = ""
          input_object.fields[7] = "NoSun"
          input_object.fields[8] = "NoWind"
          input_object.fields[9] = ""
          input_object.fields[10] = "4"
          input_object.fields[11..22] = vertices
          input_object.context = nil
          input_object.format_context
          input_file.modified = true

        when "Wall:Underground"
          puts "converting:  " + input_object.key
          old_fields = input_object.fields.dup
          vertices = SimpleGeometry.calc_vertices(input_object, coord_change, building_rotation)
          input_object.class_definition = Plugin.data_dictionary.get_class_def("BuildingSurface:Detailed")
          input_object.fields[0] = "BuildingSurface:Detailed"
          input_object.fields[1] = old_fields[1]
          input_object.fields[2] = "Wall"
          input_object.fields[3..4] = old_fields[2..3]
          input_object.fields[5] = "Ground"
          input_object.fields[6] = ""
          input_object.fields[7] = "NoSun"
          input_object.fields[8] = "NoWind"
          input_object.fields[9] = ""
          input_object.fields[10] = "4"
          input_object.fields[11..22] = vertices
          input_object.context = nil
          input_object.format_context
          input_file.modified = true

        when "Wall:Interzone"
          puts "converting:  " + input_object.key
          old_fields = input_object.fields.dup
          vertices = SimpleGeometry.calc_vertices(input_object, coord_change, building_rotation)
          input_object.class_definition = Plugin.data_dictionary.get_class_def("BuildingSurface:Detailed")
          input_object.fields[0] = "BuildingSurface:Detailed"
          input_object.fields[1] = old_fields[1]
          input_object.fields[2] = "Wall"
          input_object.fields[3..4] = old_fields[2..3]
          input_object.fields[5] = "Surface"
          input_object.fields[6] = old_fields[4]
          input_object.fields[7] = "NoSun"
          input_object.fields[8] = "NoWind"
          input_object.fields[9] = ""
          input_object.fields[10] = "4"
          input_object.fields[11..22] = vertices
          input_object.context = nil
          input_object.format_context
          input_file.modified = true

        when "Roof"
          puts "converting:  " + input_object.key
          old_fields = input_object.fields.dup
          vertices = SimpleGeometry.calc_vertices(input_object, coord_change, building_rotation)
          input_object.class_definition = Plugin.data_dictionary.get_class_def("BuildingSurface:Detailed")
          input_object.fields[0] = "BuildingSurface:Detailed"
          input_object.fields[1] = old_fields[1]
          input_object.fields[2] = "Roof"
          input_object.fields[3..4] = old_fields[2..3]
          input_object.fields[5] = "Outdoors"
          input_object.fields[6] = ""
          input_object.fields[7] = "SunExposed"
          input_object.fields[8] = "WindExposed"
          input_object.fields[9] = ""
          input_object.fields[10] = "4"
          input_object.fields[11..22] = vertices
          input_object.context = nil
          input_object.format_context
          input_file.modified = true

        when "Ceiling:Adiabatic"
          puts "converting:  " + input_object.key
          old_fields = input_object.fields.dup
          vertices = SimpleGeometry.calc_vertices(input_object, coord_change, building_rotation)
          input_object.class_definition = Plugin.data_dictionary.get_class_def("BuildingSurface:Detailed")
          input_object.fields[0] = "BuildingSurface:Detailed"
          input_object.fields[1] = old_fields[1]
          input_object.fields[2] = "Ceiling"
          input_object.fields[3..4] = old_fields[2..3]
          input_object.fields[5] = "Adiabatic"
          input_object.fields[6] = ""
          input_object.fields[7] = "NoSun"
          input_object.fields[8] = "NoWind"
          input_object.fields[9] = ""
          input_object.fields[10] = "4"
          input_object.fields[11..22] = vertices
          input_object.context = nil
          input_object.format_context
          input_file.modified = true

        when "Ceiling:Interzone"
          puts "converting:  " + input_object.key
          old_fields = input_object.fields.dup
          vertices = SimpleGeometry.calc_vertices(input_object, coord_change, building_rotation)
          input_object.class_definition = Plugin.data_dictionary.get_class_def("BuildingSurface:Detailed")
          input_object.fields[0] = "BuildingSurface:Detailed"
          input_object.fields[1] = old_fields[1]
          input_object.fields[2] = "Ceiling"
          input_object.fields[3..4] = old_fields[2..3]
          input_object.fields[5] = "Surface"
          input_object.fields[6] = old_fields[4]
          input_object.fields[7] = "NoSun"
          input_object.fields[8] = "NoWind"
          input_object.fields[9] = ""
          input_object.fields[10] = "4"
          input_object.fields[11..22] = vertices
          input_object.context = nil
          input_object.format_context
          input_file.modified = true

        when "Floor:GroundContact"
          puts "converting:  " + input_object.key
          old_fields = input_object.fields.dup
          vertices = SimpleGeometry.calc_vertices(input_object, coord_change, building_rotation)
          input_object.class_definition = Plugin.data_dictionary.get_class_def("BuildingSurface:Detailed")
          input_object.fields[0] = "BuildingSurface:Detailed"
          input_object.fields[1] = old_fields[1]
          input_object.fields[2] = "Floor"
          input_object.fields[3..4] = old_fields[2..3]
          input_object.fields[5] = "Ground"
          input_object.fields[6] = ""
          input_object.fields[7] = "NoSun"
          input_object.fields[8] = "NoWind"
          input_object.fields[9] = ""
          input_object.fields[10] = "4"
          input_object.fields[11..22] = vertices
          input_object.context = nil
          input_object.format_context
          input_file.modified = true

        when "Floor:Adiabatic"
          puts "converting:  " + input_object.key
          old_fields = input_object.fields.dup
          vertices = SimpleGeometry.calc_vertices(input_object, coord_change, building_rotation)
          input_object.class_definition = Plugin.data_dictionary.get_class_def("BuildingSurface:Detailed")
          input_object.fields[0] = "BuildingSurface:Detailed"
          input_object.fields[1] = old_fields[1]
          input_object.fields[2] = "Floor"
          input_object.fields[3..4] = old_fields[2..3]
          input_object.fields[5] = "Adiabatic"
          input_object.fields[6] = ""
          input_object.fields[7] = "NoSun"
          input_object.fields[8] = "NoWind"
          input_object.fields[9] = ""
          input_object.fields[10] = "4"
          input_object.fields[11..22] = vertices
          input_object.context = nil
          input_object.format_context
          input_file.modified = true

        when "Floor:Interzone"
          puts "converting:  " + input_object.key
          old_fields = input_object.fields.dup
          vertices = SimpleGeometry.calc_vertices(input_object, coord_change, building_rotation)
          input_object.class_definition = Plugin.data_dictionary.get_class_def("BuildingSurface:Detailed")
          input_object.fields[0] = "BuildingSurface:Detailed"
          input_object.fields[1] = old_fields[1]
          input_object.fields[2] = "Floor"
          input_object.fields[3..4] = old_fields[2..3]
          input_object.fields[5] = "Surface"
          input_object.fields[6] = old_fields[4]
          input_object.fields[7] = "NoSun"
          input_object.fields[8] = "NoWind"
          input_object.fields[9] = ""
          input_object.fields[10] = "4"
          input_object.fields[11..22] = vertices
          input_object.context = nil
          input_object.format_context
          input_file.modified = true
          
        end
      end

    end


    # Extracts the geometry data for simplified surfaces.
    def SimpleGeometry.get_geometry_parameters(input_object)
      hash = Hash.new

      case (input_object.class_definition.name)
      when "Wall:Exterior", "Wall:Adiabatic", "Wall:Underground", "Roof", "Ceiling:Adiabatic", "Floor:GroundContact", "Floor:Adiabatic"
        hash['azimuth'] = -input_object.fields[4].to_f.degrees
        hash['tilt'] = -input_object.fields[5].to_f.degrees
        hash['x1'] = input_object.fields[6].to_f
        hash['y1'] = input_object.fields[7].to_f
        hash['z1'] = input_object.fields[8].to_f
        hash['length'] = input_object.fields[9].to_f
        hash['height'] = input_object.fields[10].to_f
        
      when "Wall:Interzone", "Ceiling:Interzone", "Floor:Interzone"
        hash['azimuth'] = -input_object.fields[5].to_f.degrees
        hash['tilt'] = -input_object.fields[6].to_f.degrees
        hash['x1'] = input_object.fields[7].to_f
        hash['y1'] = input_object.fields[8].to_f
        hash['z1'] = input_object.fields[9].to_f
        hash['length'] = input_object.fields[10].to_f
        hash['height'] = input_object.fields[11].to_f
        
      when "FenestrationSurface:Detailed"
        base_surface = input_object.fields[4]
        surface_transform = SimpleGeometry.base_surface_transform(base_surface)

        vertices = input_object.fields[11..-1]
        number_of_vertices = (vertices.size / 3)
        
        points = []
        for i in 0..number_of_vertices-1
          x = vertices[i*3].to_f
          y = vertices[i*3 + 1].to_f
          z = vertices[i*3 + 2].to_f
          points[i] = Geom::Point3d.new(x, y, z)
        end

        polygon = Geom::Polygon.new(points)
        puts "before #{polygon.points}"
        polygon.transform!(surface_transform.inverse)
        puts "after #{polygon.points}"
        
        xmin = nil
        xmax = nil
        ymin = nil
        ymax = nil
        polygon.points.each do |point|
          if xmin.nil?
            xmin = -point.x
            xmax = -point.x
            ymin = -point.y
            ymax = -point.y
          else
            xmin = [xmin, -point.x].min
            xmax = [xmax, -point.x].max
            ymin = [ymin, -point.y].min
            ymax = [ymax, -point.y].max
          end
        end
        
        xoff = surface_transform.to_a[12]
        yoff = surface_transform.to_a[13]
        zoff = surface_transform.to_a[14]

        hash['x1'] = xmin
        hash['z1'] = ymin
        hash['length'] = xmax-xmin
        hash['height'] = ymax-ymin
        hash['base_surface'] = base_surface
        
      when "Window", "GlazedDoor"
        hash['x1'] = input_object.fields[7].to_f
        hash['z1'] = input_object.fields[8].to_f
        hash['length'] = input_object.fields[9].to_f
        hash['height'] = input_object.fields[10].to_f
        hash['base_surface'] = input_object.fields[3]

      when "Door"
        hash['x1'] = input_object.fields[5].to_f
        hash['z1'] = input_object.fields[6].to_f
        hash['length'] = input_object.fields[7].to_f
        hash['height'] = input_object.fields[8].to_f
        hash['base_surface'] = input_object.fields[3]

      when "Window:Interzone", "Door:Interzone", "GlazedDoor:Interzone"
        hash['x1'] = input_object.fields[6].to_f
        hash['z1'] = input_object.fields[7].to_f
        hash['length'] = input_object.fields[8].to_f
        hash['height'] = input_object.fields[9].to_f
        hash['base_surface'] = input_object.fields[3]

      when "Shading:Site", "Shading:Building"
        hash['azimuth'] = -input_object.fields[2].to_f.degrees
        hash['tilt'] = -input_object.fields[3].to_f.degrees
        hash['x1'] = input_object.fields[4].to_f
        hash['y1'] = input_object.fields[5].to_f
        hash['z1'] = input_object.fields[6].to_f
        hash['length'] = input_object.fields[7].to_f
        hash['height'] = input_object.fields[8].to_f

      when "Shading:Overhang", "Shading:Overhang:Projection"
        hash['height'] = input_object.fields[3].to_f
        hash['tilt'] = -input_object.fields[4].to_f.degrees
        hash['left'] = input_object.fields[5].to_f
        hash['right'] = input_object.fields[6].to_f
        hash['depth'] = input_object.fields[7].to_f

      when "Shading:Fin", "Shading:Fin:Projection"
        hash['margin'] = input_object.fields[3].to_f
        hash['above'] = input_object.fields[4].to_f
        hash['below'] = input_object.fields[5].to_f
        hash['tilt'] = input_object.fields[6].to_f.degrees
        hash['depth'] = input_object.fields[7].to_f
      else
        raise("Unknown class name #{input_object.class_definition.name}")
      end
      return(hash)
    end


    # Counterclockwise coordinate system is assumed.
    # Starting vertex is corrected automatically later.
    def SimpleGeometry.calc_vertices(input_object, coord_change, building_rotation, side = LEFT_SIDE)
      vertices = []
      hash = SimpleGeometry.get_geometry_parameters(input_object)

      case (input_object.class_definition.name)
      when "Shading:Site"
        length1 = hash['length']
        height1 = hash['height']

        local_transform = Geom::Transformation.new
        surface_transform = SimpleGeometry.base_surface_transform(input_object)
        zone_transform = Geom::Transformation.new


      when "Shading:Building"
        length1 = hash['length']
        height1 = hash['height']

        local_transform = Geom::Transformation.new
        surface_transform = SimpleGeometry.base_surface_transform(input_object)
        zone_transform = building_rotation


      when "Wall:Exterior", "Wall:Adiabatic", "Wall:Underground", "Roof", "Ceiling:Adiabatic", "Floor:GroundContact", 
        "Floor:Adiabatic", "Wall:Interzone", "Ceiling:Interzone", "Floor:Interzone"
        length1 = hash['length']
        height1 = hash['height']

        local_transform = Geom::Transformation.new
        surface_transform = SimpleGeometry.base_surface_transform(input_object)
        zone_transform = SimpleGeometry.zone_transform(input_object, building_rotation)


      when "Window", "Door", "GlazedDoor", "Window:Interzone", "Door:Interzone", "GlazedDoor:Interzone"
        length1 = hash['length']
        height1 = hash['height']
        
        offset_translation = Geom::Transformation.translation(Geom::Vector3d.new(-hash['x1'], -hash['z1'], 0))
        local_transform = offset_translation

        base_surface = input_object.fields[3]
        surface_transform = SimpleGeometry.base_surface_transform(base_surface)

        if (base_surface.class == InputObject)
          zone_transform = SimpleGeometry.zone_transform(base_surface, building_rotation)
        else
          zone_transform = Geom::Transformation.new
        end


      when "Shading:Overhang", "Shading:Overhang:Projection"
        sub_surface = input_object.fields[2]
        if (sub_surface.class == InputObject)
          sub_hash = SimpleGeometry.get_geometry_parameters(input_object.fields[2])

          x1 = -sub_hash['x1'] + hash['left']
          y1 = -sub_hash['z1'] - sub_hash['height'] - hash['height']

          length1 = hash['left'] + sub_hash['length'] + hash['right']

          if (input_object.class_definition.name == "Shading:Overhang:Projection")
            height1 = hash['depth'] * sub_hash['height']
          else
            height1 = hash['depth']
          end

          offset_translation = Geom::Transformation.translation(Geom::Vector3d.new(x1, y1, 0))
          #overhang_tilt = Geom::Transformation.rotation(p1, Geom::Vector3d.new(1, 0, 0), hash['tilt'])
          overhang_tilt = Geom::Transformation.rotation(Geom::Point3d.new(0, 0, 0), Geom::Vector3d.new(1, 0, 0), hash['tilt'])
          local_transform = offset_translation * overhang_tilt

          base_surface = sub_hash['base_surface']
          surface_transform = SimpleGeometry.base_surface_transform(base_surface)

          if (base_surface.class == InputObject)
            zone_transform = SimpleGeometry.zone_transform(base_surface, building_rotation)
          else
            zone_transform = Geom::Transformation.new
          end
        end


      when "Shading:Fin", "Shading:Fin:Projection"
        sub_surface = input_object.fields[2]
        if (sub_surface.class == InputObject)
          sub_hash = SimpleGeometry.get_geometry_parameters(input_object.fields[2])

          if (side == LEFT_SIDE)
            x1 = -sub_hash['x1'] + hash['margin']  # Left side
          else
            x1 = -sub_hash['x1'] - sub_hash['length'] - hash['margin']  # Right side
          end

          y1 = -sub_hash['z1'] + hash['below']
          height1 = hash['below'] + sub_hash['height'] + hash['above']

          if (input_object.class_definition.name == "Shading:Fin:Projection")
            length1 = hash['depth'] * sub_hash['length']
          else
            length1 = hash['depth']
          end

          offset_translation = Geom::Transformation.translation(Geom::Vector3d.new(x1, y1, 0))
          fin_tilt = Geom::Transformation.rotation(Geom::Point3d.new(0, 0, 0), Geom::Vector3d.new(0, 1, 0), hash['tilt'])
          local_transform = offset_translation * fin_tilt

          base_surface = sub_hash['base_surface']
          surface_transform = SimpleGeometry.base_surface_transform(base_surface)

          if (base_surface.class == InputObject)
            zone_transform = SimpleGeometry.zone_transform(base_surface, building_rotation)
          else
            zone_transform = Geom::Transformation.new
          end
        end
      end

      # Construct a rectangular polygon in the z=0 plane.
      p1 = Geom::Point3d.new(0.0, 0.0, 0.0)
      p2 = Geom::Point3d.new(-length1, 0.0, 0.0)
      p3 = Geom::Point3d.new(-length1, -height1, 0.0)
      p4 = Geom::Point3d.new(0.0, -height1, 0.0)
      polygon = Geom::Polygon.new([p1, p2, p3, p4])
      
      polygon.transform!(local_transform)
      polygon.transform!(surface_transform)

      # Apply any transformation between the normal and simple coordinate systems.
      if (coord_change == REL_TO_ABS)
        polygon.transform!(zone_transform)
      elsif (coord_change == ABS_TO_REL)
        polygon.transform!(zone_transform.inverse)
      end

      polygon.points.each { |p| vertices += [p.x.to_f, p.y.to_f, p.z.to_f] }
      #polygon.points.each { |p| vertices += [p.x.to_m.to_f, p.y.to_m.to_f, p.z.to_m.to_f] }

      return(vertices)
    end


    # Return the transformation for a base surface according to azimuth, tilt, and starting corner.
    def SimpleGeometry.base_surface_transform(input_object)
      if (input_object.class == InputObject)
        
        case input_object.class_name.upcase
          when "BUILDINGSURFACE:DETAILED","WALL:DETAILED", "ROOFCEILING:DETAILED", "FLOOR:DETAILED"
            if input_object.class_name.upcase == "BUILDINGSURFACE:DETAILED"
              number_of_vertices = input_object.fields[10].to_i
              vertices = input_object.fields[11..-1]
            else
              number_of_vertices = input_object.fields[9].to_i
              vertices = input_object.fields[10..-1]
            end
            
            if number_of_vertices == 0 # autocalculate
              number_of_vertices = (vertices.size / 3)
            end
            
            points = []
            for i in 0..number_of_vertices-1
              x = vertices[i*3].to_f
              y = vertices[i*3 + 1].to_f
              z = vertices[i*3 + 2].to_f
              points[i] = Geom::Point3d.new(x, y, z)
            end
            
            polygon = Geom::Polygon.new(points)

            # face axes
            new_z = polygon.normal

            if new_z.dot(Geom::Vector3d.new(0, 0, 1)) < 0
              #energyplus simple geometry axes
              x_axis = Geom::Vector3d.new(1, 0, 0)
              y_axis = Geom::Vector3d.new(0, 0, -1)
              z_axis = Geom::Vector3d.new(0, 1, 0)
            else
              #energyplus simple geometry axes
              x_axis = Geom::Vector3d.new(-1, 0, 0)
              y_axis = Geom::Vector3d.new(0, 0, -1)
              z_axis = Geom::Vector3d.new(0, -1, 0)
            end

            # subtract out components along new_z
            if x_axis.dot(new_z) != 0
              tmp = new_z.clone
              tmp.length = x_axis.dot(new_z)
              new_x = x_axis - tmp
            else
              new_x = x_axis.clone
            end
            
            # subtract out component along new_z
            if y_axis.dot(new_z) != 0
              tmp = new_z.clone
              tmp.length = y_axis.dot(new_z)
              new_y = y_axis - tmp
            else
              new_y = y_axis.clone
            end
            
            if new_x.length > new_y.length
              new_x.normalize!
              new_y = new_z.cross(new_x)
            else
              new_y.normalize!
              new_x = new_y.cross(new_z)
            end
            
            # find the origin, biggest x and then biggest y
            origin = points[0]
            points.each do |point|
              origin_vec = Geom::Vector3d.new(origin.x, origin.y, origin.z)
              point_vec = Geom::Vector3d.new(point.x, point.y, point.z)
              
              projected_origin_x = origin_vec.dot(new_x)
              projected_point_x = point_vec.dot(new_x)
              
              if projected_point_x > projected_origin_x
                origin = point
              elsif projected_point_x == projected_origin_x
                projected_origin_y = origin_vec.dot(new_y)
                projected_point_y = point_vec.dot(new_y)
                if projected_point_y > projected_origin_y
                  origin = point
                end
              end
            end

            surface_transform = Geom::Transformation.new(new_x, new_y, new_z, origin)

          else
        
            hash = SimpleGeometry.get_geometry_parameters(input_object)
            origin = Geom::Point3d.new(0, 0, 0)
            x_axis = Geom::Vector3d.new(1, 0, 0)
            z_axis = Geom::Vector3d.new(0, 0, 1)

            surface_tilt = Geom::Transformation.rotation(origin, x_axis, hash['tilt'])
            surface_azimuth = Geom::Transformation.rotation(origin, z_axis, hash['azimuth'])
            surface_translation = Geom::Transformation.translation(Geom::Vector3d.new(hash['x1'], hash['y1'], hash['z1']))
            surface_transform = surface_translation * surface_azimuth * surface_tilt
          end
      else
        surface_transform = Geom::Transformation.new
      end
      return(surface_transform)
    end


    # Return the transformation for the zone according to zone origin and rotation.
    def SimpleGeometry.zone_transform(input_object, building_rotation)
      if (input_object.class == InputObject)
        case input_object.class_name.upcase
          when "BUILDINGSURFACE:DETAILED"
            zone = input_object.fields[4]
          when "WALL:DETAILED", "ROOFCEILING:DETAILED", "FLOOR:DETAILED"
            zone = input_object.fields[3]
          else
            zone = input_object.fields[3]
          end
          
          if zone.class == InputObject
            origin = Geom::Point3d.new(0, 0, 0)
            z_axis = Geom::Vector3d.new(0, 0, 1)

            zone_rotation = Geom::Transformation.rotation(origin, z_axis, -zone.fields[2].to_f.degrees)
            zone_translation = Geom::Transformation.translation(Geom::Vector3d.new(zone.fields[3].to_f, zone.fields[4].to_f, zone.fields[5].to_f))
            zone_transform = zone_translation * building_rotation * zone_rotation
        end
      else
        zone_transform = building_rotation
      end
      return(zone_transform)
    end


  end

end
