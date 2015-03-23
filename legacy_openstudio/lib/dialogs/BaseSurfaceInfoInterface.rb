# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/dialogs/DialogInterface")


module LegacyOpenStudio

  class BaseSurfaceInfoInterface < DialogInterface

    def populate_hash

      @drawing_interface = Plugin.model_manager.selected_drawing_interface

      if (not @drawing_interface.nil?)
        @input_object = @drawing_interface.input_object

        @hash['NAME'] = @input_object.fields[1]
        @hash['TYPE'] = @input_object.fields[2].upcase
        @hash['CONSTRUCTION'] = @input_object.fields[3].to_s
        @hash['ZONE'] = @input_object.fields[4].to_s
        @hash['OUTSIDE_BOUNDARY_CONDITION'] = @input_object.fields[5].upcase
        @hash['OUTSIDE_BOUNDARY_OBJECT'] = @input_object.fields[6].to_s

        @hash['SUN'] = (@input_object.fields[7].upcase == "SUNEXPOSED")
        @hash['WIND'] = (@input_object.fields[8].upcase == "WINDEXPOSED")

        @hash['VIEW_FACTOR_TO_GROUND'] = @input_object.fields[9]
        
        
        # Need better method here
        if (Plugin.model_manager.units_system == "SI")
          i = 0
          gross_area = @drawing_interface.gross_area.to_m.to_m
          net_area = @drawing_interface.net_area.to_m.to_m
        else
          i = 1
          gross_area = @drawing_interface.gross_area.to_feet.to_feet
          net_area = @drawing_interface.net_area.to_feet.to_feet
        end

        @hash['AREA'] = gross_area.round_to(Plugin.model_manager.length_precision).to_s + " " + Plugin.model_manager.units_hash['m2'][i]
        @hash['NET_AREA'] = net_area.round_to(Plugin.model_manager.length_precision).to_s + " " + Plugin.model_manager.units_hash['m2'][i]
        @hash['VERTICES'] = @input_object.fields[10].to_s
        @hash['SUB_SURFACES'] = @drawing_interface.sub_surface_count
        @hash['PERCENT_GLAZING'] = @drawing_interface.percent_glazing.round_to(1).to_s + " %"
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

      # Lookup Zone object
      objects = Plugin.model_manager.input_file.find_objects_by_class_name("ZONE")
      if (object = objects.find { |object| object.name == @hash['ZONE'] })
        @input_object.fields[4] = object
      else
        @input_object.fields[4] = @hash['ZONE']
      end

      @input_object.fields[5] = @input_object.class_definition.field_definitions[5].get_choice_key(@hash['OUTSIDE_BOUNDARY_CONDITION'])

      case (@hash['OUTSIDE_BOUNDARY_CONDITION'])

      when "OUTDOORS"
        # Set some things to blank

      when "GROUND"
      
      when "GROUNDFCFACTORMETHOD"
      
      when "GROUNDSLABPREPROCESSORAVERAGE"
      
      when "GROUNDSLABPREPROCESSORCORE"
      
      when "GROUNDSLABPREPROCESSORPERIMETER"
      
      when "GROUNDBASEMENTPREPROCESSORAVERAGEWALL"
      
      when "GROUNDBASEMENTPREPROCESSORAVERAGEFLOOR"

      when "GROUNDBASEMENTPREPROCESSORUPPERWALL"
      
      when "GROUNDBASEMENTPREPROCESSORLOWERWALL"

      when "SURFACE"
        outside_boundary_object = Plugin.model_manager.input_file.find_object_by_class_and_name("BUILDINGSURFACE:DETAILED", @hash['OUTSIDE_BOUNDARY_OBJECT'])

      when "ZONE"
        outside_boundary_object = Plugin.model_manager.input_file.find_object_by_class_and_name("ZONE", @hash['OUTSIDE_BOUNDARY_OBJECT'])

      when "OTHERSIDECOEFFICIENTS"
        outside_boundary_object = Plugin.model_manager.input_file.find_object_by_class_and_name("SURFACEPROPERTY:OTHERSIDECOEFFICIENTS", @hash['OUTSIDE_BOUNDARY_OBJECT'])

      when "OTHERSIDECONDITIONSMODEL"
        outside_boundary_object = Plugin.model_manager.input_file.find_object_by_class_and_name("SURFACEPROPERTY:OTHERSIDECONDITIONSMODEL", @hash['OUTSIDE_BOUNDARY_OBJECT'])

      end

      if (outside_boundary_object.nil?)
        @input_object.fields[6] = ""
      else
        @input_object.fields[6] = outside_boundary_object
      end
      
      
      if (@hash['SUN'])
        @input_object.fields[7] = "SunExposed"
      else
        @input_object.fields[7] = "NoSun"
      end

      if (@hash['WIND'])
        @input_object.fields[8] = "WindExposed"
      else
        @input_object.fields[8] = "NoWind"
      end


      @input_object.fields[9] = @hash['VIEW_FACTOR_TO_GROUND']


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
