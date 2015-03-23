# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/dialogs/DialogInterface")
require("legacy_openstudio/lib/dialogs/RenderingSettingsDialog")


module LegacyOpenStudio

  class RenderingSettingsInterface < DialogInterface

    def initialize
      super
      @dialog = RenderingSettingsDialog.new(nil, self, @hash)
    end


    def populate_hash
      @hash['OUTPUT_FILE_PATH'] = Plugin.model_manager.results_manager.output_file_path
      @hash['RUN_PERIOD'] = Plugin.model_manager.results_manager.run_period_index
      @hash['VARIABLE_TYPE'] = Plugin.model_manager.results_manager.variable_type
      @hash['NORMALIZE'] = Plugin.model_manager.results_manager.normalize
      @hash['OUTSIDE_VARIABLE'] = Plugin.model_manager.results_manager.outside_variable_set_name
      @hash['INSIDE_VARIABLE'] = Plugin.model_manager.results_manager.inside_variable_set_name
      @hash['APPEARANCE'] = Plugin.model_manager.results_manager.rendering_appearance
      @hash['MATCH_RANGE'] = Plugin.model_manager.results_manager.match_range
      @hash['RANGE_MINIMUM'] = Plugin.model_manager.results_manager.range_minimum
      @hash['RANGE_MAXIMUM'] = Plugin.model_manager.results_manager.range_maximum
      @hash['INTERPOLATE'] = Plugin.model_manager.results_manager.interpolate
    end


    def report

      # Check the output file path
      output_file_path = @hash['OUTPUT_FILE_PATH']
      if (not output_file_path.empty? and not File.exists?(output_file_path))
        UI.messagebox("Cannot locate the output file.  Correct the output file path and try again.")
        return(false)
      end

      Plugin.model_manager.results_manager.output_file = @dialog.output_file
      Plugin.model_manager.results_manager.output_file_path = @hash['OUTPUT_FILE_PATH']
      Plugin.model_manager.results_manager.run_period_index = @hash['RUN_PERIOD'].to_i
      Plugin.model_manager.results_manager.variable_type = @hash['VARIABLE_TYPE']
      Plugin.model_manager.results_manager.normalize = @hash['NORMALIZE']
      Plugin.model_manager.results_manager.outside_variable_set_name = @hash['OUTSIDE_VARIABLE']
      Plugin.model_manager.results_manager.inside_variable_set_name = @hash['INSIDE_VARIABLE']
      Plugin.model_manager.results_manager.rendering_appearance = @hash['APPEARANCE']
      Plugin.model_manager.results_manager.match_range = @hash['MATCH_RANGE']
      Plugin.model_manager.results_manager.range_minimum = @hash['RANGE_MINIMUM']
      Plugin.model_manager.results_manager.range_maximum = @hash['RANGE_MAXIMUM']
      Plugin.model_manager.results_manager.interpolate = @hash['INTERPOLATE']
 
      Plugin.model_manager.results_manager.update

      Plugin.dialog_manager.update(ColorScaleInterface)

      Plugin.model_manager.paint
 
      return(true)
    end

  end

end
