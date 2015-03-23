# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/dialogs/Dialogs")
require("legacy_openstudio/lib/dialogs/DialogContainers")


module LegacyOpenStudio

  class AnimationSettingsDialog < PropertiesDialog

    def initialize(container, interface, hash)
      super
      w = Plugin.platform_select(373, 430)
      h = Plugin.platform_select(369, 394)
      @container = WindowContainer.new("Animation Settings", w, h, 150, 150)
      @container.set_file(Plugin.dir + "/lib/dialogs/html/AnimationSettings.html")

      add_callbacks
    end


    def add_callbacks
      super
      @container.web_dialog.add_action_callback("on_match_time_period") { on_match_time_period }
      @container.web_dialog.add_action_callback("on_match_time_step") { on_match_time_step }
    end


    def on_load
      super
      
      # Manually trigger onChange for start and end months to set the day popup options
      @container.execute_function("setDateOptions()")

      # Manually set the date values
      @container.execute_function("setElementValue('START_DATE', '" + @hash['START_DATE'].to_s + "')")
      @container.execute_function("setElementValue('END_DATE', '" + @hash['END_DATE'].to_s + "')")
    end


    def on_match_time_period

      run_period_objects = Plugin.model_manager.input_file.find_objects_by_class_name("RUNPERIOD")
 
      if (not run_period_objects.empty?)
      
        run_period = run_period_objects.to_a.first
      
        @hash['START_MONTH'] = run_period.fields[2]
        set_element_value("START_MONTH", run_period.fields[2])

        @hash['START_DATE'] = run_period.fields[3]
        set_element_value("START_DATE", run_period.fields[3])

        @hash['START_HOUR'] = "0"
        set_element_value("START_HOUR", "0")

        @hash['END_MONTH'] = run_period.fields[4]
        set_element_value("END_MONTH", run_period.fields[4])

        @hash['END_DATE'] = run_period.fields[5]
        set_element_value("END_DATE", run_period.fields[5])

        @hash['END_HOUR'] = "23"
        set_element_value("END_HOUR", "23")
      end

    end


    def on_match_time_step

      time_step_objects = Plugin.model_manager.input_file.find_objects_by_class_name("TIMESTEP")
      time_step = time_step_objects.to_a.first

      if (not time_step_objects.empty?)
        time_step_per_hour = time_step.fields[1].to_i

        if (time_step_per_hour > 0)
          time_step = (60 / time_step_per_hour).to_s
        else
          time_step = "60"
        end
      else
        time_step = "60"
      end

      @hash['TIME_STEP'] = time_step
      set_element_value("TIME_STEP", time_step)
    end

  end
  
end
