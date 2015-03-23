# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.


module LegacyOpenStudio

  class TimeInterval
    
    attr_reader :start_time, :end_time, :length


    def initialize(start_time, end_time)
      @start_time = start_time
      @end_time = end_time
      @length = (end_time - start_time).abs  # Length is in seconds
    end


    def contains?(time)
      # Uses the EnergyPlus definition of a time interval where the end time is included in the interval, but start time is not.
      return(time > @start_time and time <= @end_time)
    end
  
  end
  
end
