# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/interfaces/DrawingInterface")
require("legacy_openstudio/lib/observers/ShadowInfoObserver")

module LegacyOpenStudio

  class Building < DrawingInterface

    def create_input_object
      @input_object = InputObject.new("BUILDING")
      @input_object.fields[1] = "Untitled"
      @input_object.fields[2] = "0.0"
      @input_object.fields[3] = "Suburbs"
      @input_object.fields[4] = "0.04"
      @input_object.fields[5] = "0.4"
      @input_object.fields[6] = "FullExterior"
      @input_object.fields[7] = "25"

      super
    end
    
    # Updates the input object with the current state of the entity.
    def update_input_object
      super

      if (valid_entity?)
        # ignore north angle in SketchUp
        #@input_object.fields[2] = -@entity["NorthAngle"].to_f
      end
    end

    def parent_from_input_object
      return(Plugin.model_manager.model_interface)
    end
    
    # Building is unlike other drawing interface because it does not actually create the entity.
    # Instead it gets the current ShadowInfo object.
    def create_entity
      @entity = Sketchup.active_model.shadow_info
    end

    # Drawing interfaces that don't correspond directly to a SketchUp entity (SurfaceGeometry, Building)
    # should return false here.
    def check_entity
      return(false) 
    end

    # Updates the entity with the current state of the input object.
    def update_entity
      if (valid_entity?)
        # update entity
        #@entity["NorthAngle"] = -@input_object.fields[2].to_f

        # we will always draw detailed surfaces with true North = y
        # we want shadows to look right so synch up NorthAngle in SketchUp with detailed surface system     
        if @entity["NorthAngle"] != 0
          if not @first_time_message
            @first_time_message = true
            UI.messagebox("OpenStudio renders geometry with Y-Axis along true North, changing this will cause shadows to render differently than in EnergyPlus.")
          end
          # locking NorthAngle was too obnoxious, just warn
          #@entity["NorthAngle"] = 0
        end
      end
    end
    
    def on_change_entity
      # normally would update the idf object
      #update_input_object
      #Plugin.dialog_manager.update(BuildingInfoInterface)
      #Plugin.dialog_manager.update(ObjectInfoInterface)
      
      # here we just overwrite the entity with our idf object
      update_entity
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
    
    def azimuth
      return(@input_object.fields[2].to_f)
    end

    def transformation   # coordinate_transformation?  that's what Zone and Surface uses
      # Returns the rotation transformation in the SketchUp coordinate system.

      # EnergyPlus measures angles with positive values in the clockwise direction.
      # SketchUp measures with positive values in the counter-clockwise direction.

      origin = Geom::Point3d.new(0, 0, 0)   # Make these into plugin globals maybe
      z_axis = Geom::Vector3d.new(0, 0, 1)
      rotation_angle = (-azimuth.to_f).degrees
      return(Geom::Transformation.rotation(origin, z_axis, rotation_angle))
    end

  end

end
