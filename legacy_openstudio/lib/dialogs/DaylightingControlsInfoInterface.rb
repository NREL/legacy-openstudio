# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/dialogs/DialogInterface")


module LegacyOpenStudio

  class DaylightingControlsInfoInterface < DialogInterface

    def populate_hash
    
      @drawing_interface = Plugin.model_manager.selected_drawing_interface

      if (not @drawing_interface.nil?)
        @input_object = @drawing_interface.input_object

        @hash['NUMPOINTS'] = @input_object.fields[2].to_s
        @hash['FRAC1'] = @input_object.fields[9].to_f
        @hash['FRAC2'] = @input_object.fields[10].to_f
        @hash['SETPOINT1'] = @input_object.fields[11].to_f
        @hash['SETPOINT2'] = @input_object.fields[12].to_f
        @hash['CONTROL_TYPE'] = @input_object.fields[13].to_i
        @hash['GLARE_ANGLE'] = @input_object.fields[14].to_f
        @hash['MAX_GLARE'] = @input_object.fields[15].to_f
        @hash['INPUT_POWER_FRACTION'] = @input_object.fields[16].to_f
        @hash['OUTPUT_LIGHT_FRACTION'] = @input_object.fields[17].to_f
        @hash['NUM_STEPS'] = @input_object.fields[18].to_i
        @hash['PROB_RESET'] = @input_object.fields[19].to_f
        
        # Need better method here
        if (Plugin.model_manager.units_system == "SI")
          i = 0
          @hash['X1'] = @input_object.fields[3].to_f
          @hash['Y1'] = @input_object.fields[4].to_f
          @hash['Z1'] = @input_object.fields[5].to_f
          
          if @hash['NUMPOINTS'].to_i == 2
            @hash['X2'] = @input_object.fields[6].to_f
            @hash['Y2'] = @input_object.fields[7].to_f
            @hash['Z2'] = @input_object.fields[8].to_f
          else
            @hash['X2'] = ""
            @hash['Y2'] = ""
            @hash['Z2'] = ""
          end
        else
          i = 1
          m_to_ft = 3.2808399
          ft_to_m = 1/m_to_ft
          @hash['X1'] = (m_to_ft*@input_object.fields[3].to_f).round_to(Plugin.model_manager.length_precision)
          @hash['Y1'] = (m_to_ft*@input_object.fields[4].to_f).round_to(Plugin.model_manager.length_precision)
          @hash['Z1'] = (m_to_ft*@input_object.fields[5].to_f).round_to(Plugin.model_manager.length_precision)
          
          if @hash['NUMPOINTS'].to_i == 2
            @hash['X2'] = (m_to_ft*@input_object.fields[6].to_f).round_to(Plugin.model_manager.length_precision)
            @hash['Y2'] = (m_to_ft*@input_object.fields[7].to_f).round_to(Plugin.model_manager.length_precision)
            @hash['Z2'] = (m_to_ft*@input_object.fields[8].to_f).round_to(Plugin.model_manager.length_precision)
          else
            @hash['X2'] = ""
            @hash['Y2'] = ""
            @hash['Z2'] = ""
          end

        end
        
        @hash['X_LABEL'] = "X-Coordinate of Reference Point " + Plugin.model_manager.units_hash['m'][i] + ":"
        @hash['Y_LABEL'] = "Y-Coordinate of Reference Point " + Plugin.model_manager.units_hash['m'][i] + ":"
        @hash['Z_LABEL'] = "Z-Coordinate of Reference Point " + Plugin.model_manager.units_hash['m'][i] + ":"
        @hash['OBJECT_TEXT'] = @input_object.to_idf
      end

    end
   

    def report
    
      input_object_copy = @input_object.copy

      @input_object.fields[2] = @hash['NUMPOINTS'].to_s
      @input_object.fields[9] = @hash['FRAC1'].to_f
      @input_object.fields[10] = @hash['FRAC2'].to_f
      @input_object.fields[11] = @hash['SETPOINT1'].to_f
      @input_object.fields[12] = @hash['SETPOINT2'].to_f
      @input_object.fields[13] = @hash['CONTROL_TYPE'].to_i
      @input_object.fields[14] = @hash['GLARE_ANGLE'].to_f
      @input_object.fields[15] = @hash['MAX_GLARE'].to_f
      @input_object.fields[16] = @hash['INPUT_POWER_FRACTION'].to_f
      @input_object.fields[17] = @hash['OUTPUT_LIGHT_FRACTION'].to_f
      @input_object.fields[18] = @hash['NUM_STEPS'].to_i
      @input_object.fields[19] = @hash['PROB_RESET'].to_f

      # Need better method here
      if (Plugin.model_manager.units_system == "SI")
        i = 0
        @input_object.fields[3] = @hash['X1'].to_f
        @input_object.fields[4] = @hash['Y1'].to_f
        @input_object.fields[5] = @hash['Z1'].to_f
        
        if @input_object.fields[2].to_i == 2 and not @hash['X2'].to_s.empty? and not @hash['Y2'].to_s.empty? and not @hash['Z2'].to_s.empty?
          @input_object.fields[6] = @hash['X2'].to_f
          @input_object.fields[7] = @hash['Y2'].to_f
          @input_object.fields[8] = @hash['Z2'].to_f
        else
          @input_object.fields[6] = ""
          @input_object.fields[7] = ""
          @input_object.fields[8] = ""
        end
      else
        i = 1
        m_to_ft = 3.2808399
        ft_to_m = 1/m_to_ft
        @input_object.fields[3] = (ft_to_m*@hash['X1'].to_f).round_to(Plugin.model_manager.length_precision)
        @input_object.fields[4] = (ft_to_m*@hash['Y1'].to_f).round_to(Plugin.model_manager.length_precision)
        @input_object.fields[5] = (ft_to_m*@hash['Z1'].to_f).round_to(Plugin.model_manager.length_precision)
        
        if @input_object.fields[2].to_i == 2 and not @hash['X2'].to_s.empty? and not @hash['Y2'].to_s.empty? and not @hash['Z2'].to_s.empty?
          @input_object.fields[6] = (ft_to_m*@hash['X2'].to_f).round_to(Plugin.model_manager.length_precision)
          @input_object.fields[7] = (ft_to_m*@hash['Y2'].to_f).round_to(Plugin.model_manager.length_precision)
          @input_object.fields[8] = (ft_to_m*@hash['Z2'].to_f).round_to(Plugin.model_manager.length_precision)
        else
          @input_object.fields[6] = ""
          @input_object.fields[7] = ""
          @input_object.fields[8] = ""
        end
      end
      
      # Update object text with changes
      @hash['OBJECT_TEXT'] = @input_object.to_idf

      # Update drawing interface
      @drawing_interface.on_change_input_object

      if (@input_object != input_object_copy)
        Plugin.model_manager.input_file.modified = true
      end
      
      populate_hash

      return(true)
    end

  end

end
