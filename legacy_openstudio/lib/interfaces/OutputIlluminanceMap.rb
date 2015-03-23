# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/interfaces/DrawingInterface")
require("legacy_openstudio/lib/interfaces/Zone")
require("legacy_openstudio/lib/observers/ComponentObserver")

module LegacyOpenStudio

  class OutputIlluminanceMap < DrawingInterface
  
    @@componentdefinition = nil
    
    attr_accessor :transform, :parent
    
    def initialize
      super
      @observer = ComponentObserver.new(self)
    end
    
##### Begin override methods for the input object #####

    def create_input_object
      #puts "OutputIlluminanceMap.create_input_object"
      
      @input_object = InputObject.new("OUTPUT:ILLUMINANCEMAP")
      @input_object.fields[1] = Plugin.model_manager.input_file.new_unique_object_name
      @input_object.fields[2] = "" # Zone Name
      @input_object.fields[3] = "0.0" # Z height
      @input_object.fields[4] = "0.0" # X Minimum Coordinate
      @input_object.fields[5] = "1.0" # X Maximum Coordinate
      @input_object.fields[6] = "10" # Number of X Grid Points
      @input_object.fields[7] = "0.0" # Y Minimum Coordinate
      @input_object.fields[8] = "1.0" # Y Maximum Coordinate
      @input_object.fields[9] = "10" # Number of Y Grid Points
      
      #puts @input_object.to_idf
      
      super
    end


    def check_input_object
      #puts "OutputIlluminanceMap.check_input_object"
      return(super)
    end


    # Updates the input object with the current state of the entity.
    def update_input_object
      #puts "OutputIlluminanceMap.update_input_object"
      
      super
      
      if (valid_entity?)
      
        if @parent.nil?
          #puts "OutputIlluminanceMap.update_input_object: parent is nil"
          @parent = parent_from_input_object
        end
      
        @input_object.fields[2] = @parent.input_object  # Parent should already have been updated.
        
        decimal_places = Plugin.model_manager.length_precision
        if (decimal_places < 6)
          decimal_places = 6
          # Always keep at least 6 places for now, until I figure out how to keep the actual saved in the idf from being reduced upon loading
          # There's nothing in the API that prevents from drawing at finer precision than the option settings.
          # Just have to figure out how to keep this routine from messing it up...
          # NOTE:  Comment above applies more for surfaces than zones.
        end 
        
        # entity_transformation = entity_translation*entity_rotation*entity_scale
        # total_transformation = parent_transformation*entity_transformation
        
        # currently zone origin is separate from parent group's origin
        parent_transformation = @parent.entity.transformation
        entity_transformation = @entity.transformation
      
        sketchup_min_position = (parent_transformation*entity_transformation).origin
        #puts "sketchup_min_position = #{sketchup_min_position}"
        self.sketchup_min = sketchup_min_position
        
        # the fixed rotation angle
        rotation_angle = 0
        if (Plugin.model_manager.relative_daylighting_coordinates?)
          # for some reason building azimuth is in EnergyPlus system and zone azimuth is in SketchUp system
          rotation_angle = -Plugin.model_manager.building.azimuth + @parent.azimuth.radians
        end
        entity_rotation = Geom::Transformation.rotation([0, 0, 0], [0, 0, 1], rotation_angle.degrees)
        
        # find the current scaling
        scalex = (entity_rotation.inverse*entity_transformation).to_a[0] 
        scaley = (entity_rotation.inverse*entity_transformation).to_a[5]
        
        # get lengths
        @input_object.fields[5] = (@input_object.fields[4].to_f + scalex.to_f).round_to(decimal_places).to_s 
        @input_object.fields[8] = (@input_object.fields[7].to_f + scaley.to_f).round_to(decimal_places).to_s 

    end
  end
    
    # Returns the parent drawing interface according to the input object.
    def parent_from_input_object
      #puts "OutputIlluminanceMap.parent_from_input_object"
      
      parent = nil
      if (@input_object)
        parent = Plugin.model_manager.zones.find { |object| object.input_object.equal?(@input_object.fields[2]) }
      end
      return(parent)
    end

##### Begin override methods for the entity #####

    def create_entity
      #puts "OutputIlluminanceMap.create_entity"
      
      if (@parent.nil?)        
        #puts "OutputIlluminanceMap parent is nil"
        
        # Create a new zone just for this OutputIlluminanceMap.
        @parent = Zone.new
        @parent.create_input_object
        @parent.draw_entity(false)
        @parent.add_child(self)  # Would be nice to not have to call this
      end    
    
      # add the component definition
      path = Sketchup.find_support_file("OpenStudio_OutputIlluminanceMap.skp", "Plugins/legacy_openstudio/lib/resources/components")
      component_definition = Sketchup.active_model.definitions.load(path)
      
      # parent entity is a Sketchup::Group
      # do an identity transformation here as this transformation seems to act on child component axes twice
      @entity = @parent.entity.entities.add_instance(component_definition, Geom::Transformation.new)
      
      # make it unique as we will be messing with the definition
      @entity.make_unique
      
      # have to make the interior component unique too
      @entity.definition.entities[0].make_unique
    end

    def create_from_entity(entity)
      super
      
      # make it unique as we will be messing with the definition
      @entity.make_unique
            
      # have to make the interior component unique too
      @entity.definition.entities[0].make_unique
      
      return(self)
    end
    
    def valid_entity?
      #puts "OutputIlluminanceMap.valid_entity"
      return(super and @entity.valid?)
    end

    # Error checks, finalization, or cleanup needed after the entity is drawn.
    def confirm_entity
      #puts "OutputIlluminanceMap.confirm_entity"
      return(super)
    end

    
    # change the entity to reflect the InputObject
    def update_entity
      #puts "OutputIlluminanceMap.update_entity"
      
      super
      
      if(valid_entity?)
      
        # do not want to trigger update_input_object in here
        had_observers = remove_observers
        
        # need to make unique
        @entity.make_unique
        
        set_entity_name
        
        # scale the component to get to desired size, base size is 1mx1m so scaling is easy
        scalex = (@input_object.fields[5].to_f - @input_object.fields[4].to_f)
        scaley = (@input_object.fields[8].to_f - @input_object.fields[7].to_f)
        
        # entity_transformation = entity_translation*entity_rotation*entity_scale
        # total_transformation = parent_transformation*entity_transformation
        
        # currently zone origin is separate from parent group's origin
        parent_transformation = @parent.entity.transformation
        #puts "parent_transformation = #{parent_transformation.origin}"
        
        # the fixed rotation angle
        rotation_angle = 0
        if (Plugin.model_manager.relative_daylighting_coordinates?)
          # for some reason building azimuth is in EnergyPlus system and zone azimuth is in SketchUp system
          rotation_angle = -Plugin.model_manager.building.azimuth + @parent.azimuth.radians
        end
        entity_rotation = Geom::Transformation.rotation([0, 0, 0], [0, 0, 1], rotation_angle.degrees)
        
        # move the minimum point, no scaling yet
        transformation = parent_transformation.inverse*Geom::Transformation.translation(sketchup_min)*entity_rotation*Geom::Transformation.scaling([0,0,0], scalex, scaley, 1)
        #puts "transformation = #{transformation.origin}"
        @entity.transformation = transformation
        
        # set number of grid points        
        numx = @input_object.fields[6].to_i
        numy = @input_object.fields[9].to_i
        numx_draw = [numx-1, 0.5].max
        numy_draw = [numy-1, 0.5].max

        # The ratio below is based on assumption that the grid numbers are being
        # applied to a square face, but if the user has stretched the map I need
        # to adjust the ratio based on the aspect ratio of the stretch.
        ratio = ((numy_draw*1.0)/(numx_draw*1.0))*(scalex/scaley)*1.0
        #puts "ratio=", ratio

        if (ratio > 15)
          gridfront = "OpenStudioGrid_20"
        elsif (ratio > 7.5)
          gridfront = "OpenStudioGrid_10"
        elsif (ratio > 3)
          gridfront = "OpenStudioGrid_5"
        elsif (ratio > 0.333333)
          gridfront = "OpenStudioGrid_1"
        elsif (ratio > 0.133333)
          gridfront = "OpenStudioGrid_02"
        elsif (ratio > 0.067777)
          gridfront = "OpenStudioGrid_01"
        else
          gridfront = "OpenStudioGrid_005"
       end

        # position the texture
        pts = []
        pts[0] = [0, 0, 0]
        pts[1] = [0,0,0]
        pts[2] = [1.m, 0, 0]
        pts[3] = [numx_draw, 0, 0]
        pts[4] = [1.m, 1.m, 0]
        pts[5] = [numx_draw, numy_draw, 0]
        pts[6] = [0, 1.m, 0]
        pts[7] = [0, numy_draw, 0]
        
        # find the face
        @entity.definition.entities[0].definition.entities.each do |entity|
          if entity.is_a? Sketchup::Face
            #puts "Found face #{entity}"
            entity.position_material(gridfront, pts, true)
            entity.position_material("grid-back", pts, false)
            break
          end
        end
        
        add_observers if had_observers
        
      end
    end

    def paint_entity
      #puts "OutputIlluminanceMap.paint_entity"
      
      if (Plugin.model_manager.rendering_mode == 0)
        #paint
      elsif (Plugin.model_manager.rendering_mode == 1)
        #paint_data
      end
    end

    # Final cleanup of the entity.
    # This method is called by the model interface after the entire input file is drawn.
    def cleanup_entity
      #puts "OutputIlluminanceMap.cleanup_entity"
      super
    end

    # Returns the parent drawing interface according to the entity.
    def parent_from_entity
      #puts "OutputIlluminanceMap.parent_from_entity"
      
      parent = nil
      if (valid_entity?)
        if (@entity.parent.class == Sketchup::ComponentDefinition)
          parent = @entity.parent.instances.first.drawing_interface
        else
          # Somehow the surface got outside of a Group--maybe the Group was exploded.
        end
      end
      
      #puts "parent = #{parent}"
      return(parent)
    end


##### Begin override methods for the interface #####


##### Begin new methods for the interface #####

    def zone
      return(@input_object.fields[2])
    end
    
    def set_entity_name
      #puts "OutputIlluminanceMap.set_entity_name"
      
      if (@input_object.name.empty?)
        @entity.name = "EnergyPlus Output:IlluminanceMap:  " + "(Untitled)"
      else
        @entity.name = "EnergyPlus Output:IlluminanceMap:  " + @input_object.name
      end
    end
    
    def zone=(zone)
      #puts "OutputIlluminanceMap.zone="
      
      @input_object.fields[2] = zone.input_object
      @parent = zone     
    end

    # Gets the minimum point of the InputObject as it literally appears in the input fields.
    def input_object_min
      #puts "OutputIlluminanceMap.input_object_min"

      x = @input_object.fields[4].to_f.m
      y = @input_object.fields[7].to_f.m
      z = @input_object.fields[3].to_f.m
      
      return(Geom::Point3d.new(x, y, z))
    end
    
    # Sets the minimum point of the InputObject as it literally appears in the input fields.
    def input_object_min=(point)
      #puts "OutputIlluminanceMap.input_object_min="
      
      #puts "point is #{point[0].to_m}, #{point[1].to_m}, #{point[2].to_m}"
      
      decimal_places = Plugin.model_manager.length_precision
      if (decimal_places < 6)
        decimal_places = 6  # = 4
        # Always keep at least 4 places for now, until I figure out how to keep the actual saved in the idf from being reduced upon loading
        # There's nothing in the API that prevents from drawing at finer precision than the option settings.
        # Just have to figure out how to keep this routine from messing it up...
        
        # UPDATE:  Looks like more than 4 is necesssary to get the solar shading right in EnergyPlus, otherwise surfaces can be positioned
        # incorrectly, e.g., one wall could overlap another because of the less accurate coordinates.
      end
      format_string = "%0." + decimal_places.to_s + "f"  # This could be stored in a more central place

      x = point.x.to_m.round_to(decimal_places)
      y = point.y.to_m.round_to(decimal_places)
      z = point.z.to_m.round_to(decimal_places)

      @input_object.fields[4] = format(format_string, x)
      @input_object.fields[7] = format(format_string, y)
      @input_object.fields[3] = format(format_string, z)
    end

    # Returns the general coordinate transformation from absolute to relative.
    # The 'inverse' method can be called on the resulting transformation to go from relative to absolute.
    def coordinate_transformation
      #puts "OutputIlluminanceMap.coordinate_transformation"
      
      if (@parent.nil?)
        #puts "OutputIlluminanceMap.coordinate_transformation:  parent reference is missing"
        return(Plugin.model_manager.building.transformation)
      else
        return(@parent.coordinate_transformation)
      end
    end
    
    # Returns the point of the InputObject as they should be drawn in the relative SketchUp coordinate system.
    def sketchup_min
      #puts "OutputIlluminanceMap.sketchup_min"
      
      result = nil
      if (Plugin.model_manager.relative_daylighting_coordinates?)
        result = input_object_min.transform(coordinate_transformation)
      else
        result = input_object_min
      end
      
      return(result)
     
    end


    # Sets the point of the InputObject from the relative SketchUp coordinate system.
    def sketchup_min=(point)
      #puts "OutputIlluminanceMap.sketchup_min="
      
      #puts "point is #{point[0].to_m}, #{point[1].to_m}, #{point[2].to_m}"
      
      if (Plugin.model_manager.relative_daylighting_coordinates?)
        self.input_object_min = point.transform(coordinate_transformation.inverse)
      else
        self.input_object_min = point
      end
    end    
    
    # set to nominal 1x1 meter size once min is placed
    def reset_lengths
      #puts "OutputIlluminanceMap.reset_lengths"
      
      @input_object.fields[5] = (@input_object.fields[4].to_f + 1).to_s
      @input_object.fields[8] = (@input_object.fields[7].to_f + 1).to_s   
      
      #puts @input_object.to_idf
    end
    
    # return area in square inches
    def area
      return (@input_object.fields[5].to_f - @input_object.fields[4].to_f).m * (@input_object.fields[8].to_f - @input_object.fields[7].to_f).m
    end
    
  end

end
