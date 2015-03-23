# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require 'legacy_openstudio/lib/tools/Tool'
require 'legacy_openstudio/lib/interfaces/DaylightingControls'

module LegacyOpenStudio

  class NewDaylightingControlsTool < Tool
  
    def initialize
      @cursor = UI.create_cursor(Plugin.dir + "/lib/resources/icons/OriginToolCursor-14x20.tiff", 3, 3)
    end
    
    def onMouseMove(flags, x, y, view)
      super
      # Should apply user's precision setting here   --automatically done, I think
      # Also:  show relative coordinates?
      Sketchup.set_status_text("Select a point to insert the Daylighting:Controls = " + @ip.position.to_s)
      view.tooltip = "New Daylighting:Controls"
    end


    def onLButtonUp(flags, x, y, view)
      super

      # look for this group in the zones

      model = Sketchup.active_model
      active_path = model.active_path

      this_zone = nil
      if active_path
        Plugin.model_manager.zones.each do |zone|
          if zone.entity == active_path[-1]
            # good
            this_zone = zone
            break
          end
        end
      end

      if not this_zone
        UI.messagebox "You need to be in a Zone to add Daylighting:Controls"
        Sketchup.send_action("selectSelectionTool:")
        return false
      end

      # test to see if there are already any Daylight Control Pairs in this zone
      Plugin.model_manager.daylighting_controls.each do |daylighting_controls|
        if daylighting_controls.zone == this_zone.input_object
          UI.messagebox "Zone #{this_zone.input_object} already has Daylighting:Controls"
          Sketchup.send_action("selectSelectionTool:")
          return false
        end
      end

      Sketchup.active_model.start_operation("Daylighting:Controls")
      
      initial_position = @ip.position
      if @ip.face
        # bump up or in by 30" if placed on a face
        distance = @ip.face.normal
        distance.length = 30.0
        initial_position = initial_position - distance
      end
      
      daylighting_controls = DaylightingControls.new
      daylighting_controls.create_input_object
      daylighting_controls.zone = this_zone
      daylighting_controls.sketchup_sensor1 = initial_position
      daylighting_controls.reset_lengths
      daylighting_controls.draw_entity 

      Sketchup.active_model.selection.add(daylighting_controls.entity)
 
      Sketchup.send_action("selectSelectionTool:")
 
      Sketchup.active_model.commit_operation

    end

  end

end
