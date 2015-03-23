# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.


module LegacyOpenStudio

  VARIABLE_FREQUENCY_DETAILED = 0
  VARIABLE_FREQUENCY_TIME_STEP = 1
  VARIABLE_FREQUENCY_HOURLY = 2
  VARIABLE_FREQUENCY_DAILY = 3
  VARIABLE_FREQUENCY_MONTHLY = 4
  VARIABLE_FREQUENCY_RUN_PERIOD = 5  # Same as Environment or Annual


  class OutputVariableDefinition
    # Definition for report variables and meters in the ESO file.

    attr_accessor :key, :name, :object_name, :units, :frequency
    #attr_accessor :type  # Sum or Average; not implemented yet because this is not available in the ESO (but it is in the RDD).
    # also Report Variable or Meter
    
    def inspect
      return(self)
    end


    # outside_variable_name_and_frequency -> outside_variable_uniq_name
    # ...no...unique name includes object
    # ...maybe... outside_variable_set_name...but set is really more general
    # name, long_name, full_name

    
    def frequency_label  # frequency_name
      case(@frequency)
      when VARIABLE_FREQUENCY_RUN_PERIOD
        return("Run Period")
      when VARIABLE_FREQUENCY_MONTHLY
        return("Monthly")
      when VARIABLE_FREQUENCY_DAILY
        return("Daily")
      when VARIABLE_FREQUENCY_HOURLY
        return("Hourly")
      when VARIABLE_FREQUENCY_TIME_STEP
        return("Time Step")
      when VARIABLE_FREQUENCY_DETAILED
        return("Detailed")  # or "Each Call"
      else
        return("Unknown")
      end
    end


    def set_name
      return(@name + " (" + frequency_label + ")")
    end


    def display_name
      return(@object_name + ":" + @name + " [" + @units + "] (" + frequency_label + ")")  # Formatted similar to ReadVars column header
    end

  end

end
