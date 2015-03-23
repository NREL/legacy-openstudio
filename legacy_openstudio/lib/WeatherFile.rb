# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.


module LegacyOpenStudio

  class WeatherFile

    attr_accessor :path, :city, :state, :country, :location, :latitude, :longitude, :time_zone, :elevation
    attr_accessor :time_step, :start_day, :start_month, :start_date, :start, :end_month, :end_date, :end


    def initialize(path)
    
      if (File.exists?(path))
        @path = path
        parse_header
        analyze
      else
        puts "WeatherFile.initialize:  bad path"
      end
      
    end


    def parse_header
      
      file = File.open(path, 'r')
      
      # All geographic location information is in line 1
      line = file.gets
      array = line.split(',')
      @city = array[1].strip
      @state = array[2].strip
      @country = array[3].strip
      @location = @city + ', ' + @state + ', ' + @country
      @latitude = array[6].to_f
      @longitude = array[7].to_f
      @time_zone = array[8].to_f
      @elevation = array[9].to_f  # in meters

      # Skip the next 6 lines
      line = file.gets
      line = file.gets
      line = file.gets
      line = file.gets
      line = file.gets
      line = file.gets
      
      # All data period information is in line 8
      line = file.gets
      array = line.split(',')
      @time_step = (60.0 / array[2].to_f).to_i  # minutes
      
      @start_day = array[4].strip
      
      data_start = array[5].split('/')
      @start_month = data_start[0].to_i
      @start_date = data_start[1].to_i
      @start = @start_month.to_s + '/' + @start_date.to_s
      
      data_end = array[6].split('/')
      @end_month = data_end[0].to_i
      @end_date = data_end[1].to_i
      @end = @end_month.to_s + '/' + @end_date.to_s
      
      file.close
    end
    
    
    def analyze
      # calculate statistics, HDD, CDD, max, min
    
    end
    
    
  end
  
end
