# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.


module LegacyOpenStudio

  class DataSeries
  
    attr_accessor :variable_def, :values, :interval
    attr_accessor :length, :min, :max, :sum, :average
    #attr_accessor :intervals  # Later deal with varying time intervals between values for Detailed reporting...

    def initialize(variable_def)
      @variable_def = variable_def
      @values = []
      #@intervals = []
    end


    def inspect
      return(self)
    end
    
    def units
      return(@variable_def.units)
    end

    def add_value(value)
      # This needs to change for varying time intervals with Detailed reporting
      @values << value
    end


    def value_at(time, interpolate = false)
      # This needs to change for varying time intervals with Detailed reporting

      if (@interval.contains?(time))
        # Get the time step
        #@variable.time_step(time)
        
        
        case(@variable_def.frequency)
        when VARIABLE_FREQUENCY_RUN_PERIOD
          time_step = @interval.length  # This never gets interpolated
          
        when VARIABLE_FREQUENCY_MONTHLY
          # varies!
          time_step = 2592000  # 30 days
          # also requires variable time step intervals, just as badly as Detailed...

        when VARIABLE_FREQUENCY_DAILY
          time_step = 86400.0

        when VARIABLE_FREQUENCY_HOURLY
          time_step = 3600.0

        when VARIABLE_FREQUENCY_TIME_STEP
          
          # better to break modularity and rely on the plugin than get the wrong answer
          objects = Plugin.model_manager.input_file.find_objects_by_class_name("Timestep")
          if (objects.empty?)
            time_step = 900.0
          else
            time_step_object = objects.to_a.first
            time_step = 3600.0 / time_step_object.fields[1].to_f
          end

        when VARIABLE_FREQUENCY_DETAILED
          return(nil)
        else
          return(nil)
        end

        elapsed_time = time - @interval.start_time - 0.0000001  # Includes tiny offset to allow 'time = end_time' to return the last array element.
        index = (elapsed_time / time_step).floor

        if (interpolate and index > 0)
          # If index == 0, there is no 'before' value to interpolate with!

          elapsed_time_step = time - @interval.start_time - index * time_step
          return( ((values[index - 1] * (time_step - elapsed_time_step)) + (values[index] * elapsed_time_step)) / time_step )
        
        else
          return(values[index])
          
        end
      else
        return(nil)
      end
    end


    def finalize
      @length = @values.length
      @min = @values.min
      @max = @values.max

      series_sum = 0.0
      @values.each { |value| series_sum += value }  # Does not matter if intervals are equal.
      @sum = series_sum

      @average = @sum / @length  # Depends if intervals are equal or not

      #@integral =? # Depends if intervals are equal or not, also if averaged or summed variable
      
      #@month_sums = []  # Useful for reporting
    end

  end
  
end
