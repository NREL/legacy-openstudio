# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/dialogs/DialogInterface")
require("legacy_openstudio/lib/dialogs/RunSimulationDialog")

begin
  require("tmpdir")
rescue LoadError
  require("legacy_openstudio/stdruby/tmpdir")
end

module LegacyOpenStudio

  class RunSimulationInterface < DialogInterface

    def initialize
      super
      @dialog = RunSimulationDialog.new(nil, self, @hash)
    end

    def populate_hash
      # Read the RUN CONTROL object
      objects = Plugin.model_manager.input_file.find_objects_by_class_name("SimulationControl")
      if (objects.empty?)
        @hash['RUN_DESIGN_DAYS'] = true
        @hash['RUN_WEATHER_FILE'] = true
      else
        run_control = objects.to_a.first
        if (run_control.fields[4].upcase == "YES")
          @hash['RUN_DESIGN_DAYS'] = true
        else
          @hash['RUN_DESIGN_DAYS'] = false
        end

        if (run_control.fields[5].upcase == "YES")
          @hash['RUN_WEATHER_FILE'] = true
        else
          @hash['RUN_WEATHER_FILE'] = false
        end
      end

      @hash['RUN_DIR'] = Dir.tmpdir + "/OpenStudio/run"
      @hash['EPW_PATH'] = Plugin.model_manager.get_attribute("Weather File Path")

      # Read the RUNPERIOD object
      objects = Plugin.model_manager.input_file.find_objects_by_class_name("RunPeriod")
      if (objects.empty?)
        @hash['ANNUAL_SIMULATION'] = true
        @hash['START_MONTH'] = "1"
        @hash['START_DATE'] = "1"
        @hash['END_MONTH'] = "12"
        @hash['END_DATE'] = "31"
        @hash['START_DAY'] = "SUNDAY"
      else
        run_period = objects.to_a.first
        # Only can handle the first run period currently; multiple run periods are actually allowed in EnergyPlus.
        
        @hash['START_MONTH'] = run_period.fields[2]
        @hash['START_DATE'] = run_period.fields[3]
        @hash['END_MONTH'] = run_period.fields[4]
        @hash['END_DATE'] = run_period.fields[5]       
        @hash['START_DAY'] = run_period.fields[6].upcase
        
        if (@hash['START_MONTH'] == "1" and @hash['START_DATE'] == "1" and @hash['END_MONTH'] == "12" and @hash['END_DATE'] == "31")
          @hash['ANNUAL_SIMULATION'] = true
        else
          @hash['ANNUAL_SIMULATION'] = false
        end
      end
      
      @hash['REPORT_ABUPS'] = Plugin.model_manager.get_attribute("Report ABUPS")
      @hash['ABUPS_FORMAT'] = Plugin.model_manager.get_attribute("ABUPS Format")
      @hash['ABUPS_UNITS'] = Plugin.model_manager.get_attribute("ABUPS Units")
      @hash['REPORT_DXF'] = Plugin.model_manager.get_attribute("Report DXF")
      @hash['REPORT_SQL'] = Plugin.model_manager.get_attribute("Report Sql")
      @hash['REPORT_ZONE_TEMPS'] = Plugin.model_manager.get_attribute("Report Zone Temps")
      @hash['REPORT_SURF_TEMPS'] = Plugin.model_manager.get_attribute("Report Surface Temps")
      @hash['REPORT_DAYLIGHTING'] = Plugin.model_manager.get_attribute("Report Daylighting")
      @hash['REPORT_ZONE_LOADS'] = Plugin.model_manager.get_attribute("Report Zone Loads")
      @hash['REPORT_USER_VARS'] = Plugin.model_manager.get_attribute("Report User Variables")

      @hash['CLOSE_SHELL'] = Plugin.model_manager.get_attribute("Close Shell")
      @hash['SHOW_ERR'] = Plugin.model_manager.get_attribute("Show ERR")
      @hash['SHOW_ABUPS'] = Plugin.model_manager.get_attribute("Show ABUPS")
      @hash['SHOW_CSV'] = Plugin.model_manager.get_attribute("Show CSV")

      if (Plugin.platform == Platform_Mac)
        # Automatic close shell feature doesn't work on Mac yet.
        @hash['CLOSE_SHELL'] = false
      end
    end


    def show
      if (Plugin.simulation_manager.busy?)
        Plugin.dialog_manager.remove(self)

        UI.messagebox("EnergyPlus is already running in a shell command window.\n" +
          "To cancel the simulation, close the shell window.")
      else
        super
      end
    end


    def report

      # Save the run settings
      Plugin.model_manager.set_attribute("Weather File Path", @hash['EPW_PATH'])
      Plugin.model_manager.set_attribute("Report ABUPS", @hash['REPORT_ABUPS'])
      Plugin.model_manager.set_attribute("ABUPS Format", @hash['ABUPS_FORMAT'])
      Plugin.model_manager.set_attribute("ABUPS Units", @hash['ABUPS_UNITS'])
      Plugin.model_manager.set_attribute("Report DXF", @hash['REPORT_DXF'])
      Plugin.model_manager.set_attribute("Report Sql", @hash['REPORT_SQL'])
      Plugin.model_manager.set_attribute("Report Zone Temps", @hash['REPORT_ZONE_TEMPS'])
      Plugin.model_manager.set_attribute("Report Surface Temps", @hash['REPORT_SURF_TEMPS'])
      Plugin.model_manager.set_attribute("Report Daylighting", @hash['REPORT_DAYLIGHTING'])
      Plugin.model_manager.set_attribute("Report Zone Loads", @hash['REPORT_ZONE_LOADS'])
      Plugin.model_manager.set_attribute("Report User Variables", @hash['REPORT_USER_VARS'])
      
      Plugin.model_manager.set_attribute("Close Shell", @hash['CLOSE_SHELL'])
      Plugin.model_manager.set_attribute("Show ERR", @hash['SHOW_ERR'])
      Plugin.model_manager.set_attribute("Show ABUPS", @hash['SHOW_ABUPS'])
      Plugin.model_manager.set_attribute("Show CSV", @hash['SHOW_CSV'])

      # Configure the RUN CONTROL object
      objects = Plugin.model_manager.input_file.find_objects_by_class_name("SimulationControl")
      if (objects.empty?)
        run_control = InputObject.new("SimulationControl", ["SimulationControl", "No", "No", "No"])
        Plugin.model_manager.input_file.add_object(run_control)
      else
        run_control = objects.to_a.first
      end

      if (@hash['RUN_DESIGN_DAYS'])
        run_control.fields[4] = "Yes"
      else
        run_control.fields[4] = "No"
      end

      if (@hash['RUN_WEATHER_FILE'])
        run_control.fields[5] = "Yes"
      else
        run_control.fields[5] = "No"
      end

      # Configure the RUN PERIOD object
      objects = Plugin.model_manager.input_file.find_objects_by_class_name("RunPeriod")
      if (objects.empty?)
        run_period = InputObject.new("RunPeriod")
        Plugin.model_manager.input_file.add_object(run_period)
      else
        run_period = objects.to_a.first
      end

      run_period.fields[1] = '' # default
      run_period.fields[2] = @hash['START_MONTH']
      run_period.fields[3] = @hash['START_DATE']
      run_period.fields[4] = @hash['END_MONTH']
      run_period.fields[5] = @hash['END_DATE']
      run_period.fields[6] = @hash['START_DAY']
      
      # DLM@20101109: this fix removes a warning in the E+ error file but introduces a fatal error
      # when the last field of the run period object is blank
      # fill in fields to required length
      #(7..11).each {|i| run_period.fields[i] = "" if not run_period.fields[i]}
      
      return(true)
    end


    def run_simulation
      if (report)
        if (Plugin.simulation_manager.run_simulation)
          close
        end
      end
    end

  end

end
