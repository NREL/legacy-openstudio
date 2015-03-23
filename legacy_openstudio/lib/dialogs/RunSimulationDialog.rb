# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/dialogs/Dialogs")
require("legacy_openstudio/lib/dialogs/DialogContainers")
require("legacy_openstudio/lib/WeatherFile")


module LegacyOpenStudio

  class RunSimulationDialog < PropertiesDialog

    def initialize(container, interface, hash)
      super
      w = Plugin.platform_select(537, 600)
      h = Plugin.platform_select(770, 800)
      @container = WindowContainer.new("Run Simulation", w, h, 100, 50)
      @container.set_file(Plugin.dir + "/lib/dialogs/html/RunSimulation.html")

      add_callbacks
    end


    def add_callbacks
      super
      @container.web_dialog.add_action_callback("on_browse") { on_browse }
      @container.web_dialog.add_action_callback("on_click_annual_simulation") { |d, p| on_click_annual_simulation(d, p) }
      @container.web_dialog.add_action_callback("on_change_start_month") { |d, p| on_change_start_month(d, p) }
      @container.web_dialog.add_action_callback("on_change_end_month") { |d, p| on_change_end_month(d, p) }
      @container.web_dialog.add_action_callback("on_click_close_shell") { on_click_close_shell }
      @container.web_dialog.add_action_callback("on_run") { run_simulation }
    end


    def on_load
      super

      # Manually trigger onChange for start and end months to set the day popup options
      @container.execute_function("setDateOptions()")

      @container.execute_function("setElementValue('RUN_DIR', '" + @hash['RUN_DIR'].to_s + "')" )
      
      # Manually set the date values
      @container.execute_function("setElementValue('START_DATE', '" + @hash['START_DATE'].to_s + "')")
      @container.execute_function("setElementValue('END_DATE', '" + @hash['END_DATE'].to_s + "')")

      #if (@hash['START_DATE'] == "1" and @hash['START_MONTH'] == "1" and @hash['END_DATE'] == "12" and @hash['END_MONTH'] == "31")
      #  @hash['ANNUAL_SIMULATION'] = true
      #  set_element_value("ANNUAL_SIMULATION", @hash['ANNUAL_SIMULATION'])
      #  
      #end
      @container.execute_function("onClickAnnualSimulation()")
      @container.execute_function("onClickRunWeatherFile()")
      @container.execute_function("onClickReportABUPS()")
      @container.execute_function("onClickReportVariable()")
      
      epw_path = @hash['EPW_PATH']
      if (File.exists?(epw_path))
        show_weather_file_info(epw_path)
      end
      
      if (Plugin.platform == Platform_Mac)
        # Automatic close shell feature doesn't work on Mac yet.
        @container.execute_function("disableElement('CLOSE_SHELL')")
      end

    end


    def on_browse

      if (@hash['EPW_PATH'].empty?)
        dir = Plugin.model_manager.input_file_dir
        file_name = "*.epw"      
      else
        dir = File.dirname(@hash['EPW_PATH'])
        file_name = File.basename(@hash['EPW_PATH'])
      end

      if (epw_path = UI.open_panel("Locate Weather File", dir, file_name))

        # could replace with a single method called here and in report
        if (File.exists?(epw_path))
          epw_path = epw_path.split("\\").join("/")
          @hash['EPW_PATH'] = epw_path
          show_weather_file_info(epw_path)
          update
        end
      end
    end


    def show_weather_file_info(epw_path)
      weather_file = WeatherFile.new(epw_path)
      set_element_value("LOCATION", weather_file.location)

      set_element_value("LATITUDE", weather_file.latitude.to_s)
      set_element_value("LONGITUDE", weather_file.longitude.to_s)
      set_element_value("TIME_ZONE", weather_file.time_zone.to_s)
      set_element_value("ELEVATION", weather_file.elevation.to_s + " m")
      
      set_element_value("EPW_START", weather_file.start)
      set_element_value("EPW_END", weather_file.end)
      set_element_value("EPW_START_DAY", weather_file.start_day)
      set_element_value("TIME_STEP", weather_file.time_step.to_s + " min")
    end


    def on_click_annual_simulation(d, p)
      on_change_element(d, p)

      @hash['START_MONTH'] = "1"
      @hash['START_DATE'] = "1"
      @hash['END_MONTH'] = "12"
      @hash['END_DATE'] = "31"

      @container.execute_function("setElementValue('START_MONTH', '1')")
      @container.execute_function("setStartMonthOptions()")
      @container.execute_function("setElementValue('START_DATE', '1')")
      
      @container.execute_function("setElementValue('END_MONTH', '12')")
      @container.execute_function("setEndMonthOptions()")
      @container.execute_function("setElementValue('END_DATE', '31')")
    end


    def on_change_start_month(d, p)
      on_change_element(d, p)
      @container.execute_function("setStartMonthOptions()")
      @container.execute_function("setElementValue('START_DATE', '" + @hash['START_DATE'].to_s + "')")
    end


    def on_change_end_month(d, p)
      on_change_element(d, p)
      @container.execute_function("setEndMonthOptions()")
      @container.execute_function("setElementValue('END_DATE', '" + @hash['END_DATE'].to_s + "')")
    end


    def on_click_close_shell
      # Give a warning to the user because there is no way to distinguish between a shell command window that is 
      # running and one that is paused.
      
      if (@hash['CLOSE_SHELL'])
        UI.messagebox("Unchecking this option means that you must manually close the shell command window\n" +
          "before any of the selected results files (ERR, ABUPS, CSV) will be shown.")
      end
    end


    def run_simulation
      @interface.run_simulation
    end

  end
  
end
