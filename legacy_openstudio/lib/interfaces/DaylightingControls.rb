# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/interfaces/DrawingInterface")
require("legacy_openstudio/lib/interfaces/Zone")
require("legacy_openstudio/lib/observers/ComponentObserver")

module LegacyOpenStudio

  class DaylightingControls < DrawingInterface
  
    @@componentdefinition = nil
    
    attr_accessor :transform, :parent
    
    def initialize
      super
      @observer = ComponentObserver.new(self)
      @observer_child0 = ComponentObserver.new(self)
      @observer_child1 = ComponentObserver.new(self)
    end
    
##### Begin override methods for the input object #####

    def create_input_object

      @input_object = InputObject.new("DAYLIGHTING:CONTROLS")
      @input_object.fields[1] = # Zone
      @input_object.fields[2] = "1" # Total Daylighting Reference Points
      @input_object.fields[3] = "" # X-Coordinate of First Reference Point
      @input_object.fields[4] = "" # Y-Coordinate of First Reference Point
      @input_object.fields[5] = "" # Z-Coordinate of First Reference Point
      @input_object.fields[6] = "" # X-Coordinate of Second Reference Point
      @input_object.fields[7] = "" # Y-Coordinate of Second Reference Point
      @input_object.fields[8] = "" # Z-Coordinate of Second Reference Point
      @input_object.fields[9] = "1" # Fraction of Zone Controlled by First Reference Point
      @input_object.fields[10] = "0" # Fraction of Zone Controlled by Second Reference Point
      @input_object.fields[11] = "500" # Illuminance Setpoint at First Reference Point
      @input_object.fields[12] = "500" # Illuminance Setpoint at Second Reference Point
      @input_object.fields[13] = "1" # Lighting Control Type, 1=continuous,2=stepped,3=continuous/off
      @input_object.fields[14] = "0" # Glare Calculation Azimuth Angle of View Direction Clockwise from Zone y-Axis
      @input_object.fields[15] = "22" # Maximum Allowable Discomfort Glare Index
      @input_object.fields[16] = "0.3" # Minimum Input Power Fraction for Continuous Dimming Control
      @input_object.fields[17] = "0.2" # Minimum Light Output Fraction for Continuous Dimming Control
      @input_object.fields[18] = "1" # Number of Stepped Control Steps
      @input_object.fields[19] = "1" # Probability Lighting will be Reset When Needed in Manual Stepped Control

      super
    end
    
    def check_input_object
      return(super)
    end


    # Updates the input object with the current state of the entity.
    def update_input_object
      
      super

      if (valid_entity?)
      
        #puts "Before DaylightingControls.update_input_object"
        #puts "input_object_sensor2 = #{input_object_sensor2}"
        #puts @input_object.to_idf
      
        if @parent.nil?
          puts "DaylightingControls.update_input_object: parent is nil"
          @parent = parent_from_input_object
        end
      
        # zone
        @input_object.fields[1] = @parent.input_object  # Parent should already have been updated.
        
        decimal_places = Plugin.model_manager.length_precision
        if (decimal_places < 6)
          decimal_places = 6
          # Always keep at least 6 places for now, until I figure out how to keep the actual saved in the idf from being reduced upon loading
          # There's nothing in the API that prevents from drawing at finer precision than the option settings.
          # Just have to figure out how to keep this routine from messing it up...
          # NOTE:  Comment above applies more for surfaces than zones.
        end 
        format_string = "%0." + decimal_places.to_s + "f"  # This could be stored in a more central place
        
        # total_transformation = parent_transformation*entity_transformation*sensor_translation*sensor_rotation
        # sensor_position = parent_transformation*entity_transformation*sensor_translation*[0,0,0]
        
        # currently zone origin is separate from parent group's origin
        parent_transformation = @parent.entity.transformation
        entity_transformation = @entity.transformation
        sensor1_transformation = @entity.definition.entities[0].transformation
        sensor2_transformation = @entity.definition.entities[1].transformation
        
        # sensor 1, always have sensor one
        sensor1_position = (parent_transformation*entity_transformation*sensor1_transformation).origin
        self.sketchup_sensor1 = sensor1_position
                
        # sensor 2 position has been updated if it was blank before
        if @input_object.fields[2].to_i == 2
          if (@input_object.fields[6].to_s.empty? or @input_object.fields[7].to_s.empty? or @input_object.fields[8].to_s.empty?)
            reset_lengths
            update_entity
          else
            sensor2_position = (parent_transformation*entity_transformation*sensor2_transformation).origin
            self.sketchup_sensor2 = sensor2_position
          end
        end
        
        #puts "After DaylightingControls.update_input_object"
        #puts "input_object_sensor2 = #{input_object_sensor2}"
        #puts @input_object.to_idf
        
      end
    end
    
    # Returns the parent drawing interface according to the input object.
    def parent_from_input_object      
      parent = nil
      if (@input_object)
        parent = Plugin.model_manager.zones.find { |object| object.input_object.equal?(@input_object.fields[1]) }
      end
      return(parent)
    end

##### Begin override methods for the entity #####

    def create_entity
      if (@parent.nil?)        
        puts "DaylightingControls parent is nil"
        
        # Create a new zone just for this DaylightingControls.
        @parent = Zone.new
        @parent.create_input_object
        @parent.draw_entity(false)
        @parent.add_child(self)  # Would be nice to not have to call this
      end    

      # add the component definition
      path = Sketchup.find_support_file("OpenStudio_DaylightingControls.skp", "Plugins/legacy_openstudio/lib/resources/components")
      definition = Sketchup.active_model.definitions.load(path)
      
      # parent entity is a Sketchup::Group
      @entity = @parent.entity.entities.add_instance(definition, Geom::Transformation.new)
      
      # make it unique as we will be messing with the definition
      @entity.make_unique
    end

    def valid_entity?
      return(super and @entity.valid?)
    end

    # Error checks, finalization, or cleanup needed after the entity is drawn.
    def confirm_entity
      return(super)
    end

    # change the entity to reflect the InputObject
    def update_entity

      # do not want to call super if just want to redraw
      super
      
      if(valid_entity?)
              
        #puts "Before DaylightingControls.update_entity"
        #puts "input_object_sensor2 = #{input_object_sensor2}"
        #puts @input_object.to_idf
        
        # do not want to trigger update_input_object in here
        had_observers = remove_observers
        
        # need to make unique
        @entity.make_unique
        
        # total_transformation = parent_transformation*entity_transformation*sensor_translation*sensor_rotation
        # sensor_position = parent_transformation*entity_transformation*sensor_translation*[0,0,0]
        
        # currently zone origin is separate from parent group's origin
        parent_transformation = @parent.entity.transformation
        entity_transformation = @entity.transformation
        
        # the fixed rotation angle
        glare_angle = -@input_object.fields[14].to_f
        rotation_angle = 0
        if (Plugin.model_manager.relative_daylighting_coordinates?)
          # for some reason building azimuth is in EnergyPlus system and zone azimuth is in SketchUp system
          rotation_angle = -Plugin.model_manager.building.azimuth + @parent.azimuth.radians
        end
        sensor_rotation = Geom::Transformation.rotation([0, 0, 0], [0, 0, 1], rotation_angle.degrees+glare_angle.degrees)
            
        # move sensors, works because we have a unique definition
        sensor1_transformation = (parent_transformation*entity_transformation).inverse*Geom::Transformation.translation(sketchup_sensor1)*sensor_rotation
        #puts "sensor1_transformation = #{sensor1_transformation.origin}"
        @entity.definition.entities[0].transformation = sensor1_transformation
        
        if sketchup_sensor2
          sensor2_transformation = (parent_transformation*entity_transformation).inverse*Geom::Transformation.translation(sketchup_sensor2)*sensor_rotation
          #puts "not reset, sensor2_transformation = #{sensor2_transformation.origin}"
          @entity.definition.entities[1].transformation = sensor2_transformation
          @entity.definition.entities[1].hidden = false
        else
          sensor2_transformation = sensor1_transformation
          #puts "reset to sensor1, sensor2_transformation = #{sensor2_transformation.origin}"
          @entity.definition.entities[1].transformation = sensor2_transformation
          @entity.definition.entities[1].hidden = true
          @input_object.fields[6] = ""
          @input_object.fields[7] = ""
          @input_object.fields[8] = ""     
        end
        
        add_observers if had_observers
        
        #puts "After DaylightingControls.update_entity"
        #puts "input_object_sensor2 = #{input_object_sensor2}"
        #puts @input_object.to_idf
        
      end
      
    end

    def paint_entity
      if (Plugin.model_manager.rendering_mode == 0)
        #paint
      elsif (Plugin.model_manager.rendering_mode == 1)
        #paint_data
      end
    end

    # Final cleanup of the entity.
    # This method is called by the model interface after the entire input file is drawn.
    def cleanup_entity
      super
    end

    # Returns the parent drawing interface according to the entity.
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

    # Attaches any Observer classes, usually called after all drawing is complete.
    # Also called to reattach an Observer when a drawing interface is restored via undo.
    # This method should be overriden by subclasses.
    def add_observers 
      super # takes care of @observer only
      if (valid_entity?)
        
        # add observers for the children too
        @entity.definition.entities[0].add_observer(@observer_child0)     
        @entity.definition.entities[1].add_observer(@observer_child1)
      end
    end

    # This method can be overriden by subclasses.
    def remove_observers
      super # takes care of @observer only
      if (valid_entity?)
        
        # remove observers for the children too
        @entity.definition.entities[0].remove_observer(@observer_child0)      
        @entity.definition.entities[1].remove_observer(@observer_child1)        
      end
    end

##### Begin new methods for the interface #####
    
    def zone
      return(@input_object.fields[1])
    end
    
    def zone=(zone)
      @input_object.fields[1] = zone.input_object
      @parent = zone     
    end

    # Gets the sensor1 point of the InputObject as it literally appears in the input fields.
    def input_object_sensor1
      x = @input_object.fields[3].to_f.m
      y = @input_object.fields[4].to_f.m
      z = @input_object.fields[5].to_f.m
      
      return(Geom::Point3d.new(x, y, z))
    end
    
    # Sets the sensor1 point of the InputObject as it literally appears in the input fields.
    def input_object_sensor1=(point)
    
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

      @input_object.fields[3] = format(format_string, x)
      @input_object.fields[4] = format(format_string, y)
      @input_object.fields[5] = format(format_string, z)
    end
    
    # Gets the sensor2 point of the InputObject as it literally appears in the input fields.
    def input_object_sensor2
    
      result = nil
      
      if @input_object.fields[2].to_i == 2 and not (@input_object.fields[6].to_s.empty? or @input_object.fields[7].to_s.empty? or @input_object.fields[8].to_s.empty?)
        x = @input_object.fields[6].to_f.m
        y = @input_object.fields[7].to_f.m
        z = @input_object.fields[8].to_f.m
        result = Geom::Point3d.new(x,y,z)
      end
      
      return(result)
    end
    
    # Sets the sensor2 point of the InputObject as it literally appears in the input fields.
    def input_object_sensor2=(point)
      
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

      @input_object.fields[6] = format(format_string, x)
      @input_object.fields[7] = format(format_string, y)
      @input_object.fields[8] = format(format_string, z)
    end
    
    # Returns the general coordinate transformation from absolute to relative.
    # The 'inverse' method can be called on the resulting transformation to go from relative to absolute.
    def coordinate_transformation
      #puts "DaylightingControls.coordinate_transformation"
      
      if (@parent.nil?)
        puts "OutputIlluminanceMap.coordinate_transformation:  parent reference is missing"
        return(Plugin.model_manager.building.transformation)
      else
        return(@parent.coordinate_transformation)
      end
    end
    
    # Returns sensor1 of the InputObject as it should be drawn in the relative SketchUp coordinate system.
    def sketchup_sensor1

      result = nil
      if (Plugin.model_manager.relative_daylighting_coordinates?)
        result = input_object_sensor1.transform(coordinate_transformation)
      else
        result = input_object_sensor1
      end
      
      return(result)
     
    end

    # Sets the sensor1 of the InputObject from the relative SketchUp coordinate system.
    def sketchup_sensor1=(point)

      if (Plugin.model_manager.relative_daylighting_coordinates?)
        self.input_object_sensor1 = point.transform(coordinate_transformation.inverse)
      else
        self.input_object_sensor1 = point
      end
    end    
 
    # Returns sensor2 of the InputObject as it should be drawn in the relative SketchUp coordinate system.
    def sketchup_sensor2

      result = nil
      if (Plugin.model_manager.relative_daylighting_coordinates?)
        if input_object_sensor2
          result = input_object_sensor2.transform(coordinate_transformation)
        end
      else
        result = input_object_sensor2
      end

      return(result)

    end
 
     # Sets the sensor2 of the InputObject from the relative SketchUp coordinate system.
     def sketchup_sensor2=(point)

       if (Plugin.model_manager.relative_daylighting_coordinates?)
         self.input_object_sensor2 = point.transform(coordinate_transformation.inverse)
       else
         self.input_object_sensor2 = point
       end
    end   
    
    # set sensor2 somewhere reasonable once sensor1 is placed
    def reset_lengths

      # set number of sensors to 2
      @input_object.fields[2] = "2"
      
      @input_object.fields[6] = (@input_object.fields[3].to_f + 1).to_s
      @input_object.fields[7] = @input_object.fields[4].to_s   
      @input_object.fields[8] = @input_object.fields[5].to_s   
      
    end
    
  end

end
