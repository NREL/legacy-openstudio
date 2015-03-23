# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.
require("legacy_openstudio/lib/dialogs/DialogInterface")


module LegacyOpenStudio

  class ZoneInfoInterface < DialogInterface
  
    def populate_hash

      @drawing_interface = Plugin.model_manager.selected_drawing_interface

      if (not @drawing_interface.nil?)
        @input_object = @drawing_interface.input_object

        @hash['NAME'] = @input_object.fields[1]
        @hash['ROTATION'] = @input_object.fields[2]        
        @hash['MULTIPLIER'] = @input_object.fields[7]

        if (@input_object.fields[13].nil?)
          @hash['INCLUDE_FLOOR_AREA'] = true
        elsif (@input_object.fields[13].upcase == 'YES')
          @hash['INCLUDE_FLOOR_AREA'] = true
        else
          @hash['INCLUDE_FLOOR_AREA'] = false
        end

        @hash['SURFACES'] = @drawing_interface.base_surface_count
        @hash['SUB_SURFACES'] = @drawing_interface.sub_surface_count

        # Need better method here
        if (Plugin.model_manager.units_system == "SI")
          i = 0
          unit_floor_area = @drawing_interface.unit_floor_area.to_m.to_m
          floor_area = @drawing_interface.floor_area.to_m.to_m
          exterior_area = @drawing_interface.exterior_area.to_m.to_m
        else
          i = 1
          unit_floor_area = @drawing_interface.unit_floor_area.to_feet.to_feet
          floor_area = @drawing_interface.floor_area.to_feet.to_feet
          exterior_area = @drawing_interface.exterior_area.to_feet.to_feet
        end

        @hash['UNIT_FLOOR_AREA'] = unit_floor_area.round_to(Plugin.model_manager.length_precision).to_s + " " + Plugin.model_manager.units_hash['m2'][i]
        @hash['TOTAL_FLOOR_AREA'] = floor_area.round_to(Plugin.model_manager.length_precision).to_s + " " + Plugin.model_manager.units_hash['m2'][i]
        @hash['EXTERIOR_AREA'] = exterior_area.round_to(Plugin.model_manager.length_precision).to_s + " " + Plugin.model_manager.units_hash['m2'][i]
        @hash['PERCENT_GLAZING'] = @drawing_interface.percent_glazing.round_to(1).to_s + " %"
        @hash['OBJECT_TEXT'] = @input_object.to_idf
      end

    end


    def report
      input_object_copy = @input_object.copy

      @input_object.fields[1] = @hash['NAME']
      @input_object.fields[2] = @hash['ROTATION']
      @input_object.fields[7] = @hash['MULTIPLIER']

      if (@input_object.fields[13].nil?)
        if (@hash['INCLUDE_FLOOR_AREA'])
          # Do nothing, leave blank as before
        else
          @input_object.fields[13] = 'No'
        end
      else
        if (@hash['INCLUDE_FLOOR_AREA'])
          @input_object.fields[13] = 'Yes'
        else
          @input_object.fields[13] = 'No'
        end
      end
      
      
      # Update object text with changes
      @hash['OBJECT_TEXT'] = @input_object.to_idf

      # Update object summary because multiplier could change
      populate_hash

      # Update drawing interface
      @drawing_interface.on_change_input_object

      if (@input_object != input_object_copy)
        Plugin.model_manager.input_file.modified = true
      end

      return(true)
    end

  end

end
