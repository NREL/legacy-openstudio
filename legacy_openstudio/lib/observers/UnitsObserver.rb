# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.


module LegacyOpenStudio

  class UnitsObserver < Sketchup::OptionsProviderObserver

    # This observer seems to be called twice when it should only be called once?  could be API bug

    def onOptionsProviderChanged(options_provider, options_key)
    
      if (options_key == "LengthUnit")

        case (options_provider['LengthUnit'])
        when 0, 1
          new_units_system = "IP"
        when 2, 3, 4
          new_units_system = "SI"
        end

        if (new_units_system != Plugin.model_manager.units_system)
          Plugin.model_manager.units_system = new_units_system
          Plugin.dialog_manager.update_units
        end
      end

      if (options_key == "LengthPrecision")
        # 'LengthPrecision' ranges from 0 to 6--the number indicates the places past the decimal point
        new_precision = options_provider['LengthPrecision']
 
        if (new_precision != Plugin.model_manager.length_precision)
          Plugin.model_manager.length_precision = new_precision
          # Plugin.dialog_manager.update_units   # update any open dialogs
        end
      end


      if (options_key == "AnglePrecision")
        # 'AnglePrecision' ranges from 0 to 3--the number indicates the places past the decimal point
        new_precision = options_provider['AnglePrecision']
        
        if (new_precision != Plugin.model_manager.angle_precision)
          Plugin.model_manager.angle_precision = new_precision
          # Plugin.dialog_manager.update_units   # update any open dialogs
        end
      end

    end

  end

end
