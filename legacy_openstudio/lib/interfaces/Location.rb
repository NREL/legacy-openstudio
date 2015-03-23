# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/interfaces/DrawingInterface")
require("legacy_openstudio/lib/observers/ShadowInfoObserver")

      
module LegacyOpenStudio

  class Location < DrawingInterface

    def create_input_object
      @input_object = InputObject.new("SITE:LOCATION")
      @input_object.fields[1] = Plugin.model_manager.input_file.new_unique_object_name
      @input_object.fields[2] = "0.0"
      @input_object.fields[3] = "0.0"
      @input_object.fields[4] = "0.0"
      @input_object.fields[5] = "0.0"

      super
    end


    # Updates the input object with the current state of the entity.
    def update_input_object
      super

      if (valid_entity?)
        @input_object.fields[1] = @entity["City"]
        @input_object.fields[2] = @entity["Latitude"].to_s
        @input_object.fields[3] = @entity["Longitude"].to_s
        @input_object.fields[4] = @entity["TZOffset"].to_s
        #@input_object.fields[5] = ?  # Elevation is not handled by shadow info
      end
    end


    def parent_from_input_object
      return(Plugin.model_manager.model_interface)
    end


    # Location is unlike other drawing interface because it does not actually create the entity.
    # Instead it gets the current ShadowInfo object.
    def create_entity
      @entity = Sketchup.active_model.shadow_info
    end


    def check_entity
      return(false) 
    end


    # Updates the entity with the current state of the input object.
    def update_entity
      if (valid_entity?)
        @entity["City"] = @input_object.fields[1]
        @entity["Latitude"] = @input_object.fields[2].to_f
        @entity["Longitude"] = @input_object.fields[3].to_f
        @entity["TZOffset"] = @input_object.fields[4].to_f
        # ? = @input_object.fields[5].to_f   Elevation is not handled by shadow info
      end
    end


    def on_change_entity
      update_input_object
      Plugin.dialog_manager.update(SimulationInfoInterface)
    end


    def parent_from_entity
      return(Plugin.model_manager.model_interface)
    end


    def add_observers
      if (valid_entity?)
        @observer = ShadowInfoObserver.new(self)
        @entity.add_observer(@observer)
      end
    end
  end


end
