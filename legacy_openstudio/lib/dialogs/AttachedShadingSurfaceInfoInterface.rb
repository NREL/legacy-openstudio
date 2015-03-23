# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/dialogs/DialogInterface")


module LegacyOpenStudio

  class AttachedShadingSurfaceInfoInterface < DialogInterface

    def populate_hash
      @drawing_interface = Plugin.model_manager.selected_drawing_interface

      if (not @drawing_interface.nil?)
        @input_object = @drawing_interface.input_object

        @hash['NAME'] = @input_object.fields[1]
        @hash['BASE_SURFACE'] = @input_object.fields[2].to_s
        @hash['TRANSMITTANCE'] = @input_object.fields[3].to_s

        # Need better method here
        if (Plugin.model_manager.units_system == "SI")
          i = 0
          area = @drawing_interface.area.to_m.to_m
        else
          i = 1
          area = @drawing_interface.area.to_feet.to_feet
        end

        @hash['AREA'] = area.round_to(Plugin.model_manager.length_precision).to_s + " " + Plugin.model_manager.units_hash['m2'][i]
        @hash['VERTICES'] = @input_object.fields[4].to_s  # this should be a string already!
        @hash['OBJECT_TEXT'] = @input_object.to_idf
      end

    end


    def report
      input_object_copy = @input_object.copy

      @input_object.fields[1] = @hash['NAME']

      # Lookup base surface object
      objects = Plugin.model_manager.input_file.find_objects_by_class_name("BUILDINGSURFACE:DETAILED")
      if (object = objects.find { |object| object.name == @hash['BASE_SURFACE'] })
        @input_object.fields[2] = object
      else
        @input_object.fields[2] = @hash['BASE_SURFACE']
      end

      # Lookup transmittance schedule object
      objects = Plugin.model_manager.input_file.find_objects_by_class_name("SCHEDULE:YEAR", "SCHEDULE:COMPACT", "SCHEDULE:FILE")
      if (object = objects.find { |object| object.name == @hash['TRANSMITTANCE'] })
        @input_object.fields[3] = object
      else
        @input_object.fields[3] = @hash['TRANSMITTANCE']
      end

      # Update object text with changes
      @hash['OBJECT_TEXT'] = @input_object.to_idf

      # Update drawing interface
      @drawing_interface.on_change_input_object

      if (@input_object != input_object_copy)
        Plugin.model_manager.input_file.modified = true
      end

      return(true)
    end

  end

end
