# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/dialogs/DialogInterface")


module LegacyOpenStudio

  class SubSurfaceInfoInterface < DialogInterface

    def populate_hash

      @drawing_interface = Plugin.model_manager.selected_drawing_interface

      if (not @drawing_interface.nil?)
        @input_object = @drawing_interface.input_object

        @hash['NAME'] = @input_object.fields[1]
        @hash['TYPE'] = @input_object.fields[2].upcase
        @hash['CONSTRUCTION'] = @input_object.fields[3].to_s
        @hash['BASE_SURFACE'] = @input_object.fields[4].to_s
        @hash['OUTSIDE_BOUNDARY_OBJECT'] = @input_object.fields[5].to_s
        @hash['VIEW_FACTOR_TO_GROUND'] = @input_object.fields[6]
        @hash['SHADING_DEVICE'] = @input_object.fields[7].to_s
        @hash['FRAME_DIVIDER'] = @input_object.fields[8].to_s
        @hash['MULTIPLIER'] = @input_object.fields[9]


        # Need better method here
        if (Plugin.model_manager.units_system == "SI")
          i = 0
          unit_area = @drawing_interface.unit_area.to_m.to_m
          total_area = @drawing_interface.area.to_m.to_m
        else
          i = 1
          unit_area = @drawing_interface.unit_area.to_feet.to_feet
          total_area = @drawing_interface.area.to_feet.to_feet
        end

        @hash['VERTICES'] = @input_object.fields[10].to_s
        @hash['UNIT_AREA'] = unit_area.round_to(Plugin.model_manager.length_precision).to_s + " " + Plugin.model_manager.units_hash['m2'][i]
        @hash['TOTAL_AREA'] = total_area.round_to(Plugin.model_manager.length_precision).to_s + " " + Plugin.model_manager.units_hash['m2'][i]
        @hash['OBJECT_TEXT'] = @input_object.to_idf
      end

    end


    def report
      input_object_copy = @input_object.copy

      @input_object.fields[1] = @hash['NAME']
      @input_object.fields[2] = @input_object.class_definition.field_definitions[2].get_choice_key(@hash['TYPE'])

      # Lookup Construction object
      objects = Plugin.model_manager.construction_manager.constructions
      if (object = objects.find { |object| object.name == @hash['CONSTRUCTION'] })
        @input_object.fields[3] = object
      else
        @input_object.fields[3] = @hash['CONSTRUCTION']
      end

      # Lookup base surface object
      objects = Plugin.model_manager.input_file.find_objects_by_class_name("BUILDINGSURFACE:DETAILED")
      if (base_surface = objects.find { |object| object.name == @hash['BASE_SURFACE'] })
        @input_object.fields[4] = base_surface
      else
        @input_object.fields[4] = @hash['BASE_SURFACE']
      end

      outside_boundary_object = nil
      if (base_surface)

        case (base_surface.fields[5].upcase)

        when "OUTDOORS", "GROUND", "GROUNDFCFACTORMETHOD", "GROUNDSLABPREPROCESSORAVERAGE",
              "GROUNDSLABPREPROCESSORCORE", "GROUNDSLABPREPROCESSORPERIMETER",
              "GROUNDBASEMENTPREPROCESSORAVERAGEWALL", "GROUNDBASEMENTPREPROCESSORAVERAGEFLOOR", 
              "GROUNDBASEMENTPREPROCESSORUPPERWALL", "GROUNDBASEMENTPREPROCESSORLOWERWALL"
          # OUTSIDE_BOUNDARY_OBJECT should be blank or disabled

        when "SURFACE"
          outside_boundary_object = Plugin.model_manager.input_file.find_object_by_class_and_name("FENESTRATIONSURFACE:DETAILED", @hash['OUTSIDE_BOUNDARY_OBJECT'])

        when "OTHERSIDECOEFFICIENTS"
          outside_boundary_object = Plugin.model_manager.input_file.find_object_by_class_and_name("SURFACEPROPERTY:OTHERSIDECOEFFICIENTS", @hash['OUTSIDE_BOUNDARY_OBJECT'])

        when "ZONE"
          outside_boundary_object = Plugin.model_manager.input_file.find_object_by_class_and_name("ZONE", @hash['OUTSIDE_BOUNDARY_OBJECT'])

        when "OTHERSIDECONDITIONSMODEL"
          outside_boundary_object = Plugin.model_manager.input_file.find_object_by_class_and_name("SURFACEPROPERTY:OTHERSIDECONDITIONSMODEL", @hash['OUTSIDE_BOUNDARY_OBJECT'])

        else  # Blank
          # OUTSIDE_BOUNDARY_OBJECT should be blank or disabled
        end
      end

      if (outside_boundary_object.nil?)
        @input_object.fields[5] = ""
      else
        @input_object.fields[5] = outside_boundary_object
      end

      @input_object.fields[6] = @hash['VIEW_FACTOR_TO_GROUND']

      if (shading_device = Plugin.model_manager.input_file.find_object_by_class_and_name("WINDOWPROPERTY:SHADINGCONTROL", @hash['SHADING_DEVICE']))
        @input_object.fields[7] = shading_device
      else
        @input_object.fields[7] = @hash['SHADING_DEVICE']
      end
      
      if (frame_divider = Plugin.model_manager.input_file.find_object_by_class_and_name("WINDOWPROPERTY:FRAMEANDDIVIDER", @hash['FRAME_DIVIDER']))
        @input_object.fields[8] = frame_divider
      else
        @input_object.fields[8] = @hash['FRAME_DIVIDER']
      end

      @input_object.fields[9] = @hash['MULTIPLIER']
      # Possibly warn if > 1 and using Full Interior solar distribution

      # Update object text with changes
      @hash['OBJECT_TEXT'] = @input_object.to_idf

      # Update object summary because multiplier could change
      populate_hash

      # Update drawing interface
      @drawing_interface.on_change_input_object

      if (@input_object != input_object_copy)
        Plugin.model_manager.input_file.modified = true
      end

      return(true)  # No validation is being done right now
    end

  end

end
