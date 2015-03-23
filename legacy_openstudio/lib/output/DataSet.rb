# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

#require("legacy_openstudio/lib/output/OutputVariableDefinition")


module LegacyOpenStudio

  class DataSet
    # This is a set of DataSeries objects that have been collected for some purpose.
    # A DataSet is more dynamic than the DataSeries objects (which are static)--DataSeries can be added later.
  
    attr_accessor :data_series


    def initialize
      @data_series = []
    end


    def inspect
      return(self)
    end


    def add_data_series(new_series)
      @data_series << new_series
    end


    #def each
    
    #end


    def length
      return(@data_series.length)
    end
    
    def units
      result = ''
      if @data_series.length > 0
        result = @data_series[0].units
      end
      return(result)
    end

    def min
      # Get the minimum across all data series
      min_value = nil
      for series in @data_series
        if (min_value.nil?)
          min_value = series.min
        elsif (series.min < min_value)
          min_value = series.min
        end
      end
      return(min_value)
    end


    def max
      # Get the maximum across all data series
      max_value = nil
      for series in @data_series
        if (max_value.nil?)
          max_value = series.max
        elsif (series.max > max_value)
          max_value = series.max
        end
      end
      return(max_value)
    end


    def sum
      set_sum = 0.0
      @data_series.each { |series| set_sum += series.sum }
      return(set_sum)
    end


    def average
      if (self.length > 0)
        set_length = 0  # Number of values in the entire set
        @data_series.each { |series| set_length += series.length }
        return(self.sum / set_length)
      else
        return(nil)
      end
    end


    #def month_sums
    #end


    def write(path, interval = nil)
      # Dumps the data set to a CSV file, mainly for testing right now.

      file = File.new(path, 'w')
      
      # Write header
      header = "Time Stamp,"
      @data_series.each { |series| header += series.variable_def.display_name + "," }
      file.puts(header)
      
      # Need a way to loop through the different time intervals...  maybe have master interval list in RunPeriod

      for i in 0...@data_series[0].length
        line = "0:00,"
        
        for data_series in @data_series
          line += data_series.values[i].to_s + ","
        end
        
        file.puts(line)
      end

      file.close
    end


  end

end
