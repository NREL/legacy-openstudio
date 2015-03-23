# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/dialogs/DialogInterface")
require("legacy_openstudio/lib/dialogs/ColorScaleDialog")


module LegacyOpenStudio

  class ColorScaleInterface < DialogInterface

    def initialize
      super
      
      @dialog = ColorScaleDialog.new(nil, self, @hash)
    end


    def populate_hash

      maximum = Plugin.model_manager.results_manager.range_maximum.to_f
      minimum = Plugin.model_manager.results_manager.range_minimum.to_f
      normalize = Plugin.model_manager.results_manager.normalize

      tick = (maximum - minimum) / 5.0

      # Kludgy way to get the units, NOTE: only gets the outside units.
      outside_data_set = Plugin.model_manager.results_manager.outside_data_set
      if (outside_data_set)
        units = outside_data_set.data_series[0].variable_def.units
      else
        units = ""
      end
      
      if normalize
        normalize_suffix = ""
        if (Plugin.model_manager.units_system == "SI")
          normalize_suffix = "/m2"
        else
          normalize_suffix = "/ft2"
        end

        units += normalize_suffix
      end

      @hash['LABEL_1'] = (maximum).to_s + " " + units
      @hash['LABEL_2'] = (maximum - tick).to_s + " " + units
      @hash['LABEL_3'] = (maximum - tick * 2).to_s + " " + units
      @hash['LABEL_4'] = (maximum - tick * 3).to_s + " " + units
      @hash['LABEL_5'] = (maximum - tick * 4).to_s + " " + units
      @hash['LABEL_6'] = (maximum - tick * 5).to_s + " " + units
    end

  end

end
