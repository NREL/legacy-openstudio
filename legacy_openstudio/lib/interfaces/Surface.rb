# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/interfaces/DrawingInterface")
require("legacy_openstudio/lib/inputfile/InputObject")
require("legacy_openstudio/lib/observers/FaceObserver")


module LegacyOpenStudio

  class Surface < DrawingInterface

    attr_accessor :surface_type
    attr_accessor :outside_variable_key, :outside_value, :outside_color, :outside_texture, :outside_variable_def, :outside_normalization # for data rendering mode
    attr_accessor :inside_variable_key, :inside_value, :inside_color, :inside_texture, :inside_variable_def, :inside_normalization   # for data rendering mode


    def initialize
      super
      @observer = FaceObserver.new(self)

      @container_class = Zone
      @first_vertex_field = 0  # to be overridden
      @surface_type = nil

      @outside_variable_key = nil
      @outside_value = nil
      @outside_color = Sketchup::Color.new(255, 255, 255, 1.0)
      @outside_material = nil  # not accessible
      @outside_texture = nil
      @outside_variable_def = nil

      @inside_variable_key = nil
      @inside_value = nil
      @inside_color = Sketchup::Color.new(255, 255, 255, 1.0)
      @inside_material = nil  # not accessible
      @inside_texture = nil
      @inside_variable_def = nil
    end


##### Begin override methods for the input object #####


    # This method is overridden for each different type of surface.
    def create_input_object
      super
    end


    def check_input_object
      if (super)
        points = input_object_polygon.points

        # Check for less than 3 vertices
        if (points.length < 3)
          Plugin.model_manager.add_error("Error:  " + @input_object.key + "\n")
          Plugin.model_manager.add_error("This surface has less than 3 vertices.\n")
          Plugin.model_manager.add_error("This error cannot be automatically fixed.  The surface will not be drawn.\n\n")

          # Best outcome is that the offending surface is commented out in the code and the DrawingInterface and InputObject
          # are deleted.  This needs more supporting work before this can be done.
          delete_input_object
          #@input_object.comment_out!  # comment out the input object in the IDF

          return(false)
        end

        # Check that vertices are all in the same plane
        plane = Geom.fit_plane_to_points(points[0..2])
        new_points = []
        points.each { |point|
          if (point.on_plane?(plane))
            new_points << point
          else
            Plugin.model_manager.add_error("Error:  " + @input_object.key + "\n")
            Plugin.model_manager.add_error("Not all the vertices for this surface are in the same plane.\n")
            #Plugin.model_manager.add_error("Point out of plane distance=" + point.distance_to_plane(plane).to_s + "\n")
            Plugin.model_manager.add_error("It has been automatically fixed.\n\n")

            new_points << point.project_to_plane(plane)
          end
        }

        # OTHER CHECKS TO ADD:
        # Check for more or less vertices than 'number of vertices' flag
        # Check that no crossing lines are formed (wrong order of vertices)
        
        polygon = Geom::Polygon.new(new_points)
        polygon.reduce!  # Remove duplicate and colinear vertices

        self.input_object_polygon = polygon

        return(true)
      else
        return(false)
      end
    end


    # Updates the input object with the current state of the entity.
    def update_input_object
      super
      if (valid_entity?)
        self.surface_polygon = self.face_polygon  # Update surface vertices
      end
    end


##### Begin override methods for the entity #####


    def create_entity
      if (@parent.nil?)
        # Create a new zone just for this surface.
        @parent = @container_class.new
        @parent.create_input_object
        @parent.draw_entity(false)
        @parent.add_child(self)  # Would be nice to not have to call this
      end

      # Apply vertex order rule (Clockwise or Counterclockwise)
      if (Plugin.model_manager.surface_geometry.input_object.fields[2].upcase == "CLOCKWISE")
        points = surface_polygon.points.reverse
      else
        points = surface_polygon.points
      end
      
      @entity = group_entity.entities.add_face(points)

      # Swapping of face entities can occur with the 'add_face' method.
      # Identify and fix any swapped faces now before they can cause any trouble later.

      # The existence of 'drawing_interface' is a sign that an existing face was divided by the new face (which is true for all subsurfaces).
      # This is a prerequisite for a swap and helps eliminate some extra searching.
      if (@entity.drawing_interface)
        # Loop through all other faces in the Group to fix any swapped faces.
        # This is not an efficient technique, but it seems fast enough.
        faces = group_entity.entities.find_all { |this_entity| this_entity.class == Sketchup::Face and this_entity != @entity}

        for face in faces
          if (face.drawing_interface.entity != face)
            # Fix the swap--surprisingly this seems to be sufficient.
            face.drawing_interface.entity = face
            puts "Surface.create_entity:  fixed swap for " + face.to_s
          end
        end
      end
    end


    def valid_entity?
      return(super and @entity.valid? and @entity.area > 0)
    end


    # Error checks, finalization, or cleanup needed after the entity is drawn.
    def confirm_entity
      if (super)

        # Even though the vertex order is correct in the input object, SketchUp will sometimes draw a face
        # upside-down because of its relationship to surrounding geometry.
        if (Plugin.model_manager.surface_geometry.input_object.fields[2].upcase == "CLOCKWISE")
          if (@entity.normal.samedirection?(surface_polygon.normal))
            puts "Clockwise:  Fix unintended reversed face"
            # Fix unintended reversed face.
            @entity.reverse!
          end
        else
          if (not @entity.normal.samedirection?(surface_polygon.normal))
            puts "Counterclockwise:  Fix unintended reversed face"
            # Fix unintended reversed face.
            @entity.reverse!
          end
        end


        # ERROR CHECKS TO DO:
        # Cleanup unexpected holes in surfaces by adding a edge that slices from hole to outside.
        # Check for crossed lines...wrong vertex order.
        # Detect surfaces that are too tiny...maybe accidentally created
        # Fix near-shared vertices so that they are coincident.

        # Check to see if there was an extra face accidentally created
        # This can happen if there is an extra colinear vertex on the base face (because of other bordering faces)
        # that overlaps with the polygon of the new face.

        return(true)
      else
        return(false)
      end
    end


    def update_entity
      super

      if (input_object_polygon.points != face_polygon.points)
        #erase_entity
        #create_entity
        #puts "wants to redraw polygon"
        
        #draw_entity(false)  # Don't do this:  This is circular!
      end
    end


    def paint_entity
      if (Plugin.model_manager.rendering_mode == 0)
        paint_surface_type
      elsif (Plugin.model_manager.rendering_mode == 1)
        paint_data
      elsif (Plugin.model_manager.rendering_mode == 2)
        paint_boundary
      elsif (Plugin.model_manager.rendering_mode == 3)
        paint_layer
      elsif (Plugin.model_manager.rendering_mode == 4)
        paint_normal
      end
    end


    # Final cleanup of the entity.
    # This method is called by the model interface after the entire input file is drawn.
    def cleanup_entity
      super
    end


    # Returns the parent drawing interface according to the entity.
    # For several surfaces, the parent interface is determined by looking at the parent Group entity.
    def parent_from_entity
      parent = nil
      if (valid_entity?)
        if (@entity.parent.class == Sketchup::ComponentDefinition)
          parent = @entity.parent.instances.first.drawing_interface
        else
          # Somehow the surface got outside of a Group--maybe the Group was exploded.
        end
      end
      return(parent)
    end


##### Begin override methods for the interface #####


##### Begin new methods for the interface #####


    def input_object_polygon
      number_of_vertices = ((@input_object.fields.length - @first_vertex_field) / 3).floor

      points = []
      for i in 0..number_of_vertices-1
        # Input File API should take of error checking of fields before the input object gets here
        x = @input_object.fields[@first_vertex_field + i*3].to_f.m
        y = @input_object.fields[@first_vertex_field + i*3 + 1].to_f.m
        z = @input_object.fields[@first_vertex_field + i*3 + 2].to_f.m

        points[i] = Geom::Point3d.new(x, y, z)
      end

      return(Geom::Polygon.new(points))
    end


    # Sets the vertices of the InputObject as they should literally appear in the input fields.
    def input_object_polygon=(polygon)
      decimal_places = Plugin.model_manager.length_precision
      #if (decimal_places < 6)
        decimal_places = 12  # = 4
        # Always keep at least 4 places for now, until I figure out how to keep the actual saved in the idf from being reduced upon loading
        # There's nothing in the API that prevents from drawing at finer precision than the option settings.
        # Just have to figure out how to keep this routine from messing it up...
        
        # UPDATE:  Looks like more than 4 is necesssary to get the solar shading right in EnergyPlus, otherwise surfaces can be positioned
        # incorrectly, e.g., one wall could overlap another because of the less accurate coordinates.
      #end
      format_string = "%0." + decimal_places.to_s + "f"  # This could be stored in a more central place

      # Truncate old vertex fields in case the number of vertices is less than before
      @input_object.fields[@first_vertex_field..-1] = nil

      points = polygon.points
      number_of_vertices = points.length
      @input_object.fields[@first_vertex_field - 1] = number_of_vertices  # slightly kludgy

      for i in 0...number_of_vertices
        x = points[i].x.to_m.round_to(decimal_places)
        y = points[i].y.to_m.round_to(decimal_places)
        z = points[i].z.to_m.round_to(decimal_places)

        @input_object.fields[@first_vertex_field + i*3] = format(format_string, x)
        @input_object.fields[@first_vertex_field + i*3 + 1] = format(format_string, y)
        @input_object.fields[@first_vertex_field + i*3 + 2] = format(format_string, z)
      end
    end


    # Override in subclasses.
    def surface_type
      return(nil)
    end


    # Override in subclasses.
    def paint_surface_type
    end

    # Override in subclasses.
    def boundary
      return(nil)
    end


    # Override in subclasses.
    def paint_boundary
    end

    # Override in subclasses.
    def paint_layer
       model = Sketchup.active_model
       renderingoptions = model.rendering_options
       value = renderingoptions["DisplayColorByLayer"] = true
    end

    # Override in subclasses.
    def paint_normal
      model = Sketchup.active_model
      renderingoptions = model.rendering_options
      value = renderingoptions["RenderMode"] = 5

      front = renderingoptions["FaceFrontColor"] = "white"
      back = renderingoptions["FaceBackColor"] = "red"
    end


    # Painting with data doesn't matter what type of surface.
    def paint_data
      if (@outside_material.nil? or not @outside_material.valid?)
        # Material might have been purged as unused
        @outside_material = Sketchup.active_model.materials.add
      end
      @outside_material.color = @outside_color
      @outside_material.texture = @outside_texture

      if (@inside_material.nil? or not @inside_material.valid?)
        # Material might have been purged as unused
        @inside_material = Sketchup.active_model.materials.add
      end
      @inside_material.color = @inside_color
      @inside_material.texture = @inside_texture

      if (valid_entity?)
        @entity.material = @outside_material
        @entity.back_material = @inside_material
      end
    end


    def get_number_of_vertices  # not used yet
      # might need some safety checks here
      return( ((@input_object.fields.length - @first_vertex_field) / 3).floor )
    end


    # Returns the net area of the surface:  net = gross - subfaces
    def area
      if (valid_entity? and not deleted?)
        return(@entity.area)
      else
        return(0.0)
      end
    end


    # Returns the general coordinate transformation from absolute to relative.
    # The 'inverse' method can be called on the resulting transformation to go from relative to absolute.
    def coordinate_transformation
      if (@parent.nil?)
        puts "Surface.coordinate_transformation:  parent reference is missing"
        return(Plugin.model_manager.building.transformation)
      else
        return(@parent.coordinate_transformation)
      end
    end


    # Returns the vertices of the InputObject as they should be drawn in the SketchUp coordinate system.
    # If everything is up-to-date, surface_polygon == face_polygon.
    def surface_polygon
      if (Plugin.model_manager.relative_coordinates?)
        return(input_object_polygon.transform(coordinate_transformation))
      else
        return(input_object_polygon)
      end
    end


    # Sets the vertices of the InputObject according to the coordinate system.
    def surface_polygon=(polygon)
      if (Plugin.model_manager.relative_coordinates?)
        self.input_object_polygon = polygon.transform(coordinate_transformation.inverse)
      else
        self.input_object_polygon = polygon
      end
    end


    # Returns the polygon of the face in absolute coordinates.
    # NOTE:  BaseSurface overrides this method significantly.
    def face_polygon  # entity_polygon
      if (valid_entity?)
        points = @entity.absolute_polygon.outer_loop.reduce  # removes colinear points
        points = apply_surface_geometry(points)
        return(Geom::Polygon.new(points))
      else
        puts "Surface.face_polygon:  entity not valid"
        return(nil)
      end
    end


    # Sets the vertices of the Face object in the SketchUp model.
    # Not implemented yet.
    def face_polygon=(polygon)
      # Not sure if I will use this.
      # The same effect can be achieved from an erase and a draw, which must be done anyway to change the
      # vertices of a face.

      puts "Surface:  face_polygon= called but not yet implemented."
    end


    def apply_surface_geometry(points)
      temp_points = points

      # Apply vertex order rule (Clockwise or Counterclockwise)
      if (Plugin.model_manager.surface_geometry.input_object.fields[2].upcase == "CLOCKWISE")
        temp_points.reverse!
      end


      ## Apply first vertex rule (UpperLeftCorner, LowerLeftCorner, UpperRightCorner, LowerRightCorner)

      # Find a bounding rectangle that just fits the points

      # Get x and y unit vectors for the local relative coordinate axes in the plane of the face
      axes = @entity.normal.axes
      x_axis = axes[0]
      y_axis = axes[1]

      # Find centroid
      centroid = Geom::Vector3d.new(0, 0, 0)
      length_sum = 0
      for point in temp_points
        vector = Geom::Vector3d.new(point.x, point.y, point.z)
        centroid += vector
        length_sum += vector.length
      end

      centroid.scale!(1.0 / temp_points.length)

      center_point = Geom::Point3d.new(centroid.x, centroid.y, centroid.z)

      #Sketchup.active_model.entities.add_cpoint(center_point)
      #Sketchup.active_model.entities.add_cline(center_point, x_axis)
      #Sketchup.active_model.entities.add_cline(center_point, y_axis)

      x_min = x_max = 0.0
      y_min = y_max = 0.0

      for point in temp_points
        vertex_vector = Geom::Vector3d.new(point.x, point.y, point.z) - centroid

        x = x_axis % vertex_vector
        if (x < x_min)
          x_min = x
        end
        if (x > x_max)
          x_max = x
        end

        y = y_axis % vertex_vector
        if (y < y_min)
          y_min = y
        end
        if (y > y_max)
          y_max = y
        end
      end

      case (Plugin.model_manager.surface_geometry.input_object.fields[1].upcase)

      when "UPPERLEFTCORNER"
        corner = centroid + x_axis.scale(x_min) + y_axis.scale(y_max)  # ULC
      when "LOWERLEFTCORNER"
        corner = centroid + x_axis.scale(x_min) + y_axis.scale(y_min)  # LLC
      when "UPPERRIGHTCORNER"
        corner = centroid + x_axis.scale(x_max) + y_axis.scale(y_max)  # URC
      when "LOWERRIGHTCORNER"
        corner = centroid + x_axis.scale(x_max) + y_axis.scale(y_min)  # LRC
      else
        puts "Surface.apply_surface_geometry:  bad first vertex"
      end

      #cp1 = Sketchup.active_model.entities.add_cpoint(Geom::Point3d.new(cn1.x, cn1.y, cn1.z))
      #cp2 = Sketchup.active_model.entities.add_cpoint(Geom::Point3d.new(cn2.x, cn2.y, cn2.z))
      #cp3 = Sketchup.active_model.entities.add_cpoint(Geom::Point3d.new(cn3.x, cn3.y, cn3.z))
      #cp4 = Sketchup.active_model.entities.add_cpoint(Geom::Point3d.new(cn4.x, cn4.y, cn4.z))

      first_point = 0
      shortest_distance = nil
      for i in 0...temp_points.length
        point = temp_points[i]
        vector = Geom::Vector3d.new(point.x, point.y, point.z)
        distance_to_point = (corner - vector).length.abs

        if (shortest_distance.nil? or distance_to_point < shortest_distance)
          shortest_distance = distance_to_point
          first_point = i
        end
      end

      if (first_point > 0)
        new_points = temp_points[first_point..-1] + temp_points[0..(first_point - 1)]
      else
        new_points = temp_points
      end

      #fp = Sketchup.active_model.entities.add_cpoint(Geom::Point3d.new(new_points[0].x, new_points[0].y, new_points[0].z))
      #Sketchup.active_model.selection.clear
      #Sketchup.active_model.selection.add(fp)

      return(new_points)
    end

  end

end
