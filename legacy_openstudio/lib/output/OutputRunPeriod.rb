# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/output/TimeInterval")
require("legacy_openstudio/lib/output/DataSeries")
require("legacy_openstudio/lib/output/DataSet")


module LegacyOpenStudio

  RUN_PERIOD_TYPE_UNKNOWN = 0
  RUN_PERIOD_TYPE_DESIGN_DAY = 1
  RUN_PERIOD_TYPE_WEATHER_FILE = 2


  class OutputRunPeriod
    # NOTE:  Because of the format of the ESO file, if hourly (or shorter) variables are not reported, it is impossible
    #        to determine the actual start and end dates of the run period.  Generally, the user will have the hourly
    #        variables if the plan to do any visualization of data.  Yes, the run period information is available in the
    #        IDF which is probably already in memory, but it would destroy the modularity if it was accessed from here.
    #        Workaround is to have ResultsManager try to match up DESIGNDAY and RUNPERIOD objects and get the dates from them.

    attr_accessor :name, :latitude, :longitude, :time_zone, :elevation
    attr_accessor :type  # DesignDay or WeatherFile, this cannot be determined from the ESO yet, but it is set by ResultsManager later.
    attr_accessor :start_month, :start_date, :end_month, :end_date, :length, :interval
    attr_accessor :variable_defs, :data_series, :data_sets
    
    def initialize
      @name = nil
      @latitude = nil
      @longitude = nil
      @time_zone = nil
      @elevation = nil

      @start_month = nil
      @start_date = nil

      @end_month = nil
      @end_date = nil

      @length = 0
      @interval = nil
      @type = RUN_PERIOD_TYPE_UNKNOWN  # DesignDay or WeatherFile, this cannot be determined from the ESO yet.

      @variable_defs = Hash.new  # Should be set by OutputFile
      @data_series = Hash.new
      @data_sets = Hash.new
    end


    def inspect
      return(self)
    end


    def display_name
      if (start_month == end_month and start_date == end_date)
        return(name + " (" + start_month.to_s + "/" + start_date.to_s + ")")
      else
        return(name + " (" + start_month.to_s + "/" + start_date.to_s + "-" + end_month.to_s + "/" + end_date.to_s + ")")
      end
    end
    
    
    def add_value(key, value)
      if (@data_series[key].nil?)
        @data_series[key] = DataSeries.new(@variable_defs[key])
      end
      @data_series[key].add_value(value)  # Later deal with varying time intervals between values for Detailed reporting...
    end


    def finalize
      start_time = Time.utc(Time.now.year, @start_month, @start_date)
      end_time = start_time + (@length * 86400) - 1
      @interval = TimeInterval.new(start_time, end_time)

      @end_month = end_time.month
      @end_date = end_time.day
      
      @data_series.each_value { |series|
        series.interval = @interval
        series.finalize
      }

      # Create default data set for all variables
      @data_sets["All Variables"] = DataSet.new
      @data_series.each_value { |series| @data_sets["All Variables"].add_data_series(series) }

      # Create default data sets by variable name and reporting frequency
      for variable_def in @variable_defs.values
        if (@data_sets[variable_def.set_name].nil?)
          @data_sets[variable_def.set_name] = DataSet.new
        end
      end

      @data_series.each_value { |series|
        @data_sets[series.variable_def.set_name].add_data_series(series)
      }
    end
    
    
    #def write(path)
      # Dump the data set "All Variables" to a CSV file.
    #end

  end
  
end
