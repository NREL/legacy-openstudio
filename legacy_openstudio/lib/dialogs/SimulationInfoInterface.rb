# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/dialogs/DialogInterface")
require("legacy_openstudio/lib/dialogs/SimulationInfoDialog")


module LegacyOpenStudio

  class SimulationInfoInterface < DialogInterface

    def initialize
      super
      @dialog = SimulationInfoDialog.new(nil, self, @hash)
    end


    def populate_hash
      input_object = Plugin.model_manager.surface_geometry.input_object

      if (input_object.fields[3].upcase == "RELATIVE")
        @hash['COORDINATE_SYSTEM'] = "RELATIVE"
      else
        @hash['COORDINATE_SYSTEM'] = "ABSOLUTE"
      end
      
      if (input_object.fields[4] and input_object.fields[4].upcase == "ABSOLUTE")
        @hash['DAYLIGHTING_COORDINATE_SYSTEM'] = "ABSOLUTE"
      else
        @hash['DAYLIGHTING_COORDINATE_SYSTEM'] = "RELATIVE"
      end
      
      if (input_object.fields[5] and input_object.fields[5].upcase == "ABSOLUTE")
        @hash['RECTANGULAR_COORDINATE_SYSTEM'] = "ABSOLUTE"
      else
        @hash['RECTANGULAR_COORDINATE_SYSTEM'] = "RELATIVE"
      end

      @hash['VERTEX_ORDER'] = input_object.fields[2].upcase

      case(input_object.fields[1].upcase)
      when "UPPERLEFTCORNER"
        @hash['STARTING_VERTEX'] = "UPPER_LEFT_CORNER"

      when "LOWERLEFTCORNER"
        @hash['STARTING_VERTEX'] = "LOWER_LEFT_CORNER"

      when "UPPERRIGHTCORNER"
        @hash['STARTING_VERTEX'] = "UPPER_RIGHT_CORNER"

      when "LOWERRIGHTCORNER"
        @hash['STARTING_VERTEX'] = "LOWER_RIGHT_CORNER"
      end

      input_object = Plugin.model_manager.location.input_object
      if (input_object)
        @hash['LOCATION_NAME'] = input_object.fields[1]
        @hash['LATITUDE'] = input_object.fields[2]
        @hash['LONGITUDE'] = input_object.fields[3]
        @hash['TIME_ZONE'] = input_object.fields[4]
        @hash['ELEVATION'] = input_object.fields[5]
      else
        puts "This file has no location."
      end
      
    end


    def report
      # Must handle SurfaceGeometry first because changing Location will trigger the ShadowInfoObserver which, in turn, updates this interface.

      # Report SurfaceGeometry input object
      input_object = Plugin.model_manager.surface_geometry.input_object
      input_object_copy = input_object.copy

      if (@hash['COORDINATE_SYSTEM'] == "RELATIVE")
        input_object.fields[3] = "Relative"
      else
        input_object.fields[3] = "Absolute"
      end
      
      if (@hash['DAYLIGHTING_COORDINATE_SYSTEM'] == "RELATIVE")
        input_object.fields[4] = "Relative"
      else
        input_object.fields[4] = "Absolute"
      end
      
      if (@hash['RECTANGULAR_COORDINATE_SYSTEM'] == "RELATIVE")
        input_object.fields[5] = "Relative"
      else
        input_object.fields[5] = "Absolute"
      end
      
      if (@hash['VERTEX_ORDER'] == "CLOCKWISE")
        input_object.fields[2] = "Clockwise"
      else
        input_object.fields[2] = "Counterclockwise"
      end

      case(@hash['STARTING_VERTEX'])

      when "UPPER_LEFT_CORNER"
        input_object.fields[1] = "UpperLeftCorner"

      when "LOWER_LEFT_CORNER"
        input_object.fields[1] = "LowerLeftCorner"

      when "UPPER_RIGHT_CORNER"
        input_object.fields[1] = "UpperRightCorner"
        
      when "LOWER_RIGHT_CORNER"
        input_object.fields[1] = "LowerRightCorner"
      end

      Plugin.model_manager.surface_geometry.on_change_input_object  #.recalculate_vertices
      # There is a problem with putting 'recalculate_vertices' in the draw method
      # because it saves the existing vertices of any persistent drawing interfaces
      # and does not allow them to update with the new input object values.

      if (input_object != input_object_copy)
        Plugin.model_manager.input_file.modified = true
      end

      # Report Location input object
      input_object = Plugin.model_manager.location.input_object

      input_object.fields[1] = @hash['LOCATION_NAME']
      input_object.fields[2] = @hash['LATITUDE']
      input_object.fields[3] = @hash['LONGITUDE']
      input_object.fields[4] = @hash['TIME_ZONE']
      input_object.fields[5] = @hash['ELEVATION']

      # Update drawing interface
      Plugin.model_manager.location.on_change_input_object

      if (input_object != input_object_copy)
        Plugin.model_manager.input_file.modified = true
      end

      Plugin.dialog_manager.update(SimulationInfoInterface)
      Plugin.dialog_manager.update(ObjectInfoInterface)

      return(true)
    end


  end

end
