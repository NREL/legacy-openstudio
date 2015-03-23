# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/inputfile/InputObject")
require("legacy_openstudio/lib/interfaces/Surface")
require("legacy_openstudio/lib/interfaces/DetachedShadingGroup")


module LegacyOpenStudio

  class DetachedShadingSurface < Surface


    # Drawing interface is being created because an input object is being loaded.
    # Overridden to set 'surface_type' flag.
    def self.new_from_input_object(input_object)
      drawing_interface = self.new
      drawing_interface.input_object = input_object

      if (input_object.is_class_name?("SHADING:SITE:DETAILED"))
        drawing_interface.surface_type = 0
      else
        drawing_interface.surface_type = 1
      end
      return(drawing_interface)
    end


    def initialize
      super
      @container_class = DetachedShadingGroup
      @first_vertex_field = 4
      @surface_type = 1  # 0 = Fixed, 1 = Building
    end


##### Begin methods for the input object #####


    def create_input_object
      if (@surface_type == 0)
        @input_object = InputObject.new("SHADING:SITE:DETAILED")
      else
        @input_object = InputObject.new("SHADING:BUILDING:DETAILED")
      end
      @input_object.fields[1] = Plugin.model_manager.input_file.new_unique_object_name
      @input_object.fields[2] = ""
      @input_object.fields[3] = ""
      @input_object.fields[4] = 0  # kludge to make fields list long enough for call below

      super
    end


    # Updates the input object with the current state of the entity.
    def update_input_object
      super  # Surface superclass updates the vertices
    end


    def parent_from_input_object
    
      update_parent_from_entity  # This is really the wrong place...
      
      return(nil)
    end


##### Begin methods for the entity #####


    def update_entity
      #super  # overridden here

      update_parent_from_entity  # This is key for getting the parent!

      if (input_object_polygon.points != face_polygon.points)
        #erase_entity
        #create_entity
        
        #draw_entity(false)  # Don't do this:  This is circular!
      end
    end


##### Begin override methods for the interface #####


    def coordinate_transformation
      # Returns the general coordinate transformation from absolute to relative.
      # The 'inverse' method can be called on the resulting transformation to go from relative to absolute.

      #if (@parent.nil?)
      #  puts "DetachedShadingSurface.coordinate_transformation:  parent shading group is missing"
      #  return(Geom::Transformation.new)  # Identity transformation
      #else
      #  return(@parent.coordinate_transformation)
      #end

      # Kind of a kludge...parent surface_type was not being set correctly.
      # For now, ignore the parent coordinate transformation.  There's no extra data there anyway.
      if (@surface_type == 0)
        @parent.surface_type = 0
        return(Geom::Transformation.new)  # Identity transformation
      else
        @parent.surface_type = 1
        return(Plugin.model_manager.building.transformation)
      end
    end


    def surface_relative_polygon
      if (@surface_type == 0)
        return(input_object_polygon)
      else
        return(input_object_polygon.transform(coordinate_transformation))  # same as 'super'
      end
    end
    
    def in_selection?(selection)
      return (selection.contains?(@entity) or selection.contains?(@parent.entity))
    end

    def paint_surface_type
      if (valid_entity?)
        if (@surface_type == 0)
          @entity.material = Plugin.model_manager.construction_manager.detached_fixed_shading
          @entity.back_material = Plugin.model_manager.construction_manager.detached_fixed_shading_back
        else
          @entity.material = Plugin.model_manager.construction_manager.detached_building_shading
          @entity.back_material = Plugin.model_manager.construction_manager.detached_building_shading_back
        end
      end
    end


##### Begin new methods for the interface #####


    attr_reader :surface_type


    def surface_type=(new_type)
      @surface_type = new_type
      if (@surface_type == 0)
        @input_object.class_definition = Plugin.data_dictionary.get_class_def("SHADING:SITE:DETAILED")
        @input_object.fields[0] = Plugin.data_dictionary.get_class_def("SHADING:SITE:DETAILED").name  # shouldn't have to do this
      else
        @input_object.class_definition = Plugin.data_dictionary.get_class_def("SHADING:BUILDING:DETAILED")
        @input_object.fields[0] = Plugin.data_dictionary.get_class_def("SHADING:BUILDING:DETAILED").name  # shouldn't have to do this
      end

      paint_entity
    end


  end

end
