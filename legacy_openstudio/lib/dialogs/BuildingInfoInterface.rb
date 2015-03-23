# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/dialogs/DialogInterface")


module LegacyOpenStudio

  class BuildingInfoInterface < DialogInterface
  
    def populate_hash

      @drawing_interface = Plugin.model_manager.selected_drawing_interface

      if (not @drawing_interface.nil?)
        @input_object = @drawing_interface.input_object

        @hash['NAME'] = @input_object.fields[1]
        @hash['ROTATION'] = @input_object.fields[2]        
        @hash['TERRAIN'] = @input_object.fields[3].upcase
        @hash['LOADS_TOLERANCE'] = @input_object.fields[4]
        @hash['TEMPERATURE_TOLERANCE'] = @input_object.fields[5]
        @hash['SOLAR_DISTRIBUTION'] = @input_object.fields[6].upcase
        @hash['MAX_WARMUP_DAYS'] = @input_object.fields[7]

        zones = Plugin.model_manager.zones
        @hash['ZONES'] = zones.count

        floor_area = 0.0
        exterior_area = 0.0  # Exterior
        exterior_glazing_area = 0.0  # Exterior
        for zone in zones
          if (zone.include_in_building_floor_area?)
            floor_area += zone.floor_area
          end
          
          exterior_area += zone.exterior_area
          exterior_glazing_area += zone.exterior_glazing_area
        end

        if (exterior_area > 0.0)
          percent_glazing = 100.0 * exterior_glazing_area / exterior_area
        else
          percent_glazing = 0.0
        end

        # Need better method here
        if (Plugin.model_manager.units_system == "SI")
          i = 0
          floor_area = floor_area.to_m.to_m
          exterior_area = exterior_area.to_m.to_m
        else
          i = 1
          floor_area = floor_area.to_feet.to_feet
          exterior_area = exterior_area.to_feet.to_feet
        end
        
        @hash['FLOOR_AREA'] = floor_area.round_to(Plugin.model_manager.length_precision).to_s + " " + Plugin.model_manager.units_hash['m2'][i]
        @hash['EXTERIOR_AREA'] = exterior_area.round_to(Plugin.model_manager.length_precision).to_s + " " + Plugin.model_manager.units_hash['m2'][i]
        @hash['PERCENT_GLAZING'] = percent_glazing.round_to(1).to_s + " %"
        @hash['OBJECT_TEXT'] = @input_object.to_idf
      end

    end


    def report
      input_object_copy = @input_object.copy

      @input_object.fields[1] = @hash['NAME']
      @input_object.fields[2] = @hash['ROTATION']
      @input_object.fields[3] = @input_object.class_definition.field_definitions[3].get_choice_key(@hash['TERRAIN'])
      @input_object.fields[4] = @hash['LOADS_TOLERANCE']
      @input_object.fields[5] = @hash['TEMPERATURE_TOLERANCE']
      @input_object.fields[6] = @input_object.class_definition.field_definitions[6].get_choice_key(@hash['SOLAR_DISTRIBUTION'])
      @input_object.fields[7] = @hash['MAX_WARMUP_DAYS']

      # Update object text with changes
      @hash['OBJECT_TEXT'] = @input_object.to_idf

      # Update drawing interface
      # Needs to transform all zones if the Building Axis has changed.

      if (@input_object != input_object_copy)
        Plugin.model_manager.input_file.modified = true
      end
      
      # Update drawing interface
      Plugin.model_manager.building.on_change_input_object
      
      return(true)
    end

  end

end
