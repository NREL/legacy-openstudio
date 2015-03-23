# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/output/OutputVariableDefinition")
require("legacy_openstudio/lib/output/OutputRunPeriod")


module LegacyOpenStudio

  class OutputFile

    attr_accessor :path, :variable_defs, :run_periods, :data_series


    def OutputFile.open(path, update_progress = nil)
      return(new(path, update_progress))
    end


    def initialize(path, update_progress = nil)
      $d = self
      open(path, update_progress)
    end


    def open(path, update_progress = nil)
      # As a method call outside of 'initialize', this allows the output file to be reopened.

      @variable_defs = Hash.new
      @run_periods = []
      
      update_progress.update_progress(0, "Reading Output File")

      if (File.exists?(path))
      
        @path = path
        
        if Plugin.read_pref("Cache Eso Results")
        
          # check for cached results
          cached_path = path + ".cache"
          if File.exists?(cached_path) and (File.new(path).mtime < File.new(cached_path).mtime)

            # load cached data
            File.open(cached_path, 'r') do |file|
              cached = Marshal.load(file)
              @path = cached.path
              @variable_defs = cached.variable_defs
              @run_periods = cached.run_periods
              @data_series = cached.data_series
            end
            
          else
          
            # read data
            read_output_file(update_progress)

            # path may not be writable, File.writable? is not giving good results
            begin
              # save data to cache
              File.open(cached_path, 'w') do |file|
                Marshal.dump(self, file)
              end
            rescue
            end
            
          end
          
        else
          
          # just read the data
          read_output_file(update_progress)
          
        end
        
      else
        puts "OutputFile.open:  bad path"
      end
    end


    def inspect
      return(self)
    end


    def read_output_file(update_progress = nil)

      file = File.open(@path, 'r')

    #read_variable_dictionary

      # Skip the first 6 lines--they are always the same
      6.times { file.gets }

      # Read all of the keys into a hash
      while (line = file.gets)
        break if (line.index("End of Data Dictionary"))

        # test strings:
        # 95,1,Electricity:Facility [J] !Hourly [Value,Min,Minute,Max,Minute]
        # 4023,1,Carbon Equivalent:Facility [kg] !Monthly [Value,Min,Day,Hour,Minute,Max,Day,Hour,Minute]
        # 62737,2,FLOOR 1 LOCKER ROOM VAV BOX REHEAT COIL,Total Water Heating Coil Energy [J] !Hourly
        # 63427,2,FLOOR 3 UNDEVELOPED 1 VAV BOX REHEAT COIL,Heating Coil Rate[W] !Hourly
        # 63474,2,AHU-2,AirLoopHVAC Minimum Outdoor Air Fraction !Hourly
        # 699,2,4D61FFZONEHVAC:IDEALLOADSAIRSYSTEM,Ideal Loads Air Sensible Cooling Rate[W] !Hourly
        match_data = /(\d+),(\d+),?(.*?),(.*?)(\[.*?\])?\s?!([^\[]*)/.match(line)
        
        if match_data.nil? or match_data.length < 7
          puts line
        end
     
        key = match_data[1].to_i
        type = match_data[2].to_i
        object_name = match_data[3].strip
        object_name = object_name.gsub(/ZONEHVAC.*/, '') # special case
        variable_name = match_data[4].strip
        if match_data[5].nil?
          units = ""
        else
          units = match_data[5].gsub(/[\[\]]/,"").strip
        end
        frequency = match_data[6].strip
        
        case(frequency.upcase)
        when "EACH CALL"
          frequency = VARIABLE_FREQUENCY_DETAILED
        when "TIMESTEP"
          frequency = VARIABLE_FREQUENCY_TIME_STEP
        when "HOURLY"
          frequency = VARIABLE_FREQUENCY_HOURLY
        when "DAILY"
          frequency = VARIABLE_FREQUENCY_DAILY
        when "MONTHLY"
          frequency = VARIABLE_FREQUENCY_MONTHLY
        when "RUNPERIOD", "ENVIRONMENT", "ANNUAL"
          frequency = VARIABLE_FREQUENCY_RUN_PERIOD
        end        

        @variable_defs[key] = OutputVariableDefinition.new
        @variable_defs[key].key = key
        @variable_defs[key].name = variable_name
        #@variable_defs[key].type = type  # Here 'type' is report variable or meter
        @variable_defs[key].object_name = object_name
        @variable_defs[key].units = units
        @variable_defs[key].frequency = frequency
      end


    #read_run_periods
    
      # NOTE:  Because of the format of the ESO file, if hourly (or shorter) variables are not reported, it is impossible
      #        to determine the actual start and end dates of the run period.  Generally, the user will have the hourly
      #        variables if the plan to do any visualization of data.  Yes, the run period information is available in the
      #        IDF which is probably already in memory, but it would destroy the modularity if it was accessed from here.

      while (line = file.gets)
        break if (line == "End of Data\n")

        $line = line

        array = line.split(',')
        key = array[0].to_i
        value = array[1].to_f

        month = 1
        date = 1

        case(key)
        when 1  # New environment, new run period
          
          # Start a new run period
          run_period = OutputRunPeriod.new
          run_period.variable_defs = @variable_defs  # This is instead of creating an OutputDataDictionary class          
          run_period.name = array[1].strip
          run_period.latitude = array[2].strip
          run_period.longitude = array[3].strip
          run_period.time_zone = array[4].strip
          run_period.elevation = array[5].strip

          @run_periods << run_period

        when 2  # Time stamp for Hourly. Time Step, or Detailed variables
          month = array[2].to_i
          date = array[3].to_i
          #dst = array[4]
          #day_type = array[8]  # WinterDesignDay, SummerDesignDay, Monday, Tuesday, etc...

        when 3  # Time stamp for Daily variables
          month = array[2].to_i
          date = array[3].to_i

        when 4  # Time stamps for Monthly variables
          month = array[2].to_i

        when 5  # Time stamps for Run Period variables
          # Do nothing

        else
          # Regular report variable or meter record
          run_period.add_value(key, value)
        end

        if (key > 1 and key < 6)
          run_period.length = array[1].to_i  # Days of simulation
          
          # assume annual simulation
          update_progress.update_progress((100.0 * array[1].to_f/365.0), "Reading Output File")

          if (run_period.start_month.nil?)
            run_period.start_month = month
            run_period.start_date = date
          end
        end
        
      end
      
      # ResultsManager also calls 'finalize' but with better dates...don't want to call it twice.
      #@run_periods.each { |run_period| run_period.finalize }  

      file.close
    end
    
    
    def get_variable_key(name, object_name)
      for variable_def in @variable_defs.values
        if (variable_def.name == name and variable_def.object_name == object_name)
          return(variable_def.key)
        end
      end
      return(nil)
    end

  end

end
