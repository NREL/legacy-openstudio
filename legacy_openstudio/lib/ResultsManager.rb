# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/output/OutputFile")
require("legacy_openstudio/lib/dialogs/ProgressDialog")


module LegacyOpenStudio

  class ResultsManager
  
    attr_accessor :output_file_path, :output_file, :run_period
    attr_accessor :run_period_index, :variable_type, :rendering_appearance
    attr_accessor :match_range, :range_minimum, :range_maximum, :interpolate, :normalize
    attr_accessor :outside_variable_set_name, :outside_data_set
    attr_accessor :inside_variable_set_name, :inside_data_set


    def initialize
      @output_file = nil
      @output_file_path = Plugin.model_manager.get_attribute("Output File Path")

      # check the file to see if modified data is more recent, reload the data file
      # or even if file exists

      @run_period_index = Plugin.model_manager.get_attribute("Run Period").to_i
      @variable_type = Plugin.model_manager.get_attribute("Variable Type")
      @normalize = Plugin.model_manager.get_attribute("Normalize")
      @outside_variable_set_name = Plugin.model_manager.get_attribute("Outside Variable")
      @inside_variable_set_name = Plugin.model_manager.get_attribute("Inside Variable")
      @rendering_appearance = Plugin.model_manager.get_attribute("Appearance")
      @match_range = Plugin.model_manager.get_attribute("Match Range")
      @range_minimum = Plugin.model_manager.get_attribute("Range Minimum")
      @range_maximum = Plugin.model_manager.get_attribute("Range Maximum")
      @interpolate = Plugin.model_manager.get_attribute("Interpolate")
    end


    def update
      Plugin.model_manager.set_attribute("Output File Path", @output_file_path)
      Plugin.model_manager.set_attribute("Run Period", @run_period_index.to_s)
      Plugin.model_manager.set_attribute("Variable Type", @variable_type)
      Plugin.model_manager.set_attribute("Normalize", @normalize)
      Plugin.model_manager.set_attribute("Outside Variable", @outside_variable_set_name)
      Plugin.model_manager.set_attribute("Inside Variable", @inside_variable_set_name)
      Plugin.model_manager.set_attribute("Appearance", @rendering_appearance)
      Plugin.model_manager.set_attribute("Match Range", @match_range)
      Plugin.model_manager.set_attribute("Range Minimum", @range_minimum)
      Plugin.model_manager.set_attribute("Range Maximum", @range_maximum)
      Plugin.model_manager.set_attribute("Interpolate", @interpolate)

      puts "@run_period_index = #{@run_period_index}"
      if (@output_file)
        @outside_data_set = @output_file.run_periods[@run_period_index].data_sets[@outside_variable_set_name]
        @inside_data_set = @output_file.run_periods[@run_period_index].data_sets[@inside_variable_set_name]
        
        puts "@outside_data_set = #{@outside_data_set}"
        puts "@inside_data_set = #{@inside_data_set}"
      end
      
      # Call DrawingManager to update variable keys on all surfaces
      Plugin.model_manager.update_surface_variable_keys
    end


    # NOTE:  This is a class method so that it can be called from outside the context of the ResultsManager to process a file before
    #        it is saved on the Results Manager--for instance, for the output file selection dialog.
    def ResultsManager.process_output_file(output_file_path)

      progress_dialog = ProgressDialog.new
      begin
        output_file = OutputFile.new(output_file_path, progress_dialog)
      ensure
        progress_dialog.destroy
      end
      
      # Kludge to fix the run periods because DataRunPeriod cannot always get the accurate start and end dates for the run period,
      # the info must be cross-referenced to the RUNPERIOD objects and DESIGNDAY objects.
      run_periods = output_file.run_periods.clone

      # First check the DESIGNDAYS--they are easier because they have names.
      Plugin.model_manager.input_file.find_objects_by_class_name("SizingPeriod:WeatherFileDays").each { |design_day|
        for i in 0...run_periods.length
          run_period = run_periods[i]
          if (not run_period.nil? and run_period.name == design_day.fields[1].upcase)

            run_period.type = RUN_PERIOD_TYPE_DESIGN_DAY
            
            run_period.start_month = design_day.fields[2].to_i
            run_period.start_date = design_day.fields[3].to_i
            run_period.end_month = run_period.start_month
            run_period.end_date = run_period.start_date

            start_time = Time.utc(Time.now.year, run_period.start_month, run_period.start_date)
            end_time = start_time + 86400
            run_period.interval = TimeInterval.new(start_time, end_time)

            run_periods[i] = nil  # Remove the run period from the array so it doesn't get picked twice.
          end
        end
      }

      run_periods.compact!

      # Check the RUNPERIOD objects--they should be in the same order in the ESO as in the IDF
      run_period_input_objects = Plugin.model_manager.input_file.find_objects_by_class_name("RunPeriod").to_a
      for i in 0...run_period_input_objects.length
        run_period_input_object = run_period_input_objects[i]
        run_period = run_periods[i]

        if (not run_period_input_object.nil? and not run_period.nil?)

          run_period.type = RUN_PERIOD_TYPE_WEATHER_FILE

          run_period.start_month = run_period_input_object.fields[2].to_i
          run_period.start_date = run_period_input_object.fields[3].to_i
          run_period.end_month = run_period_input_object.fields[4].to_i
          run_period.end_date = run_period_input_object.fields[5].to_i

          start_time = Time.utc(Time.now.year, run_period.start_month, run_period.start_date)
          end_time = Time.utc(Time.now.year, run_period.end_month, run_period.end_date)
          run_period.interval = TimeInterval.new(start_time, end_time)
        end
      end
      
      # Kludge to re-finalize everything now that better start and end dates are specified.
      output_file.run_periods.each { |run_period| run_period.finalize }
      
      return(output_file)
    end


# Old stuff below
    def show_results
      #path = File.dirname(Plugin.energyplus_path) + "/eplustbl.htm"
      #if (File.exists?(path))
      #  $results = parse_abups_html

      #  ResultsInterface.show
      #end
    end


    def parse_abups_html
    
      path = File.dirname(Plugin.energyplus_path) + "/eplustbl.htm"
      
      if (not File.exists?(path))
        return
      end
      
      file = File.open(path, 'r')
      
      results = []

      while (line = file.gets)
      
        line.strip!
        
        case (line)
        
        when ('<td align="right">Heating</td>')
          energy = 0
          for i in 0..4
            line = file.gets
            energy += line[22..33].strip.to_f
          end
          results[0] = energy

        when ('<td align="right">Cooling</td>')
          energy = 0
          for i in 0..4
            line = file.gets
            energy += line[22..33].strip.to_f
          end
          results[1] = energy
          
        when ('<td align="right">Interior Lighting</td>')
          energy = 0
          for i in 0..4
            line = file.gets
            energy += line[22..33].strip.to_f
          end
          results[2] = energy
          
        when ('<td align="right">Exterior Lighting</td>')
          energy = 0
          for i in 0..4
            line = file.gets
            energy += line[22..33].strip.to_f
          end
          results[3] = energy
          
        when ('<td align="right">Interior Equipment</td>')
          energy = 0
          for i in 0..4
            line = file.gets
            energy += line[22..33].strip.to_f
          end
          results[4] = energy
          
        when ('<td align="right">Exterior Equipment</td>')
          energy = 0
          for i in 0..4
            line = file.gets
            energy += line[22..33].strip.to_f
          end
          results[5] = energy
          
        when ('<td align="right">Fans</td>')
          energy = 0
          for i in 0..4
            line = file.gets
            energy += line[22..33].strip.to_f
          end
          results[6] = energy
          
        when ('<td align="right">Pumps</td>')
          energy = 0
          for i in 0..4
            line = file.gets
            energy += line[22..33].strip.to_f
          end
          results[7] = energy

        when ('<td align="right">Heat Rejection</td>')
          energy = 0
          for i in 0..4
            line = file.gets
            energy += line[22..33].strip.to_f
          end
          results[8] = energy
          
        when ('<td align="right">Humidification</td>')
          energy = 0
          for i in 0..4
            line = file.gets
            energy += line[22..33].strip.to_f
          end
          results[9] = energy
          
        when ('<td align="right">Heat Recovery</td>')
          energy = 0
          for i in 0..4
            line = file.gets
            energy += line[22..33].strip.to_f
          end
          results[10] = energy
          
        when ('<td align="right">Water Systems</td>')
          energy = 0
          for i in 0..4
            line = file.gets
            energy += line[22..33].strip.to_f
          end
          results[11] = energy
          
        when ('<td align="right">Refrigeration</td>')
          energy = 0
          for i in 0..4
            line = file.gets
            energy += line[22..33].strip.to_f
          end
          results[12] = energy
          
        when ('<td align="right">Generators</td>')
          energy = 0
          for i in 0..4
            line = file.gets
            energy += line[22..33].strip.to_f
          end
          results[13] = energy
          
          break  # Break out of the while loop
          
        else
          # do nothing
        
        end
      
      
      end
      
      for i in 0...results.length
        if (results[i] == 0.0)
          results[i] = 0.001
        end
      end
      
      
      file.close

      return(results)    
    end
  
  
  end
  
end
