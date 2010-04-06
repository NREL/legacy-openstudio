# OpenStudio
# Copyright (c) 2008-2009 Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require 'OpenStudio/lib/tools/Tool'
require 'OpenStudio/lib/interfaces/OutputIlluminanceMap'

module OpenStudio

  class NewOutputIlluminanceMapTool < Tool
  
    def initialize
      @cursor = UI.create_cursor(Plugin.dir + "/lib/resources/icons/OriginToolCursor-14x20.tiff", 3, 3)
    end
    
    def onMouseMove(flags, x, y, view)
      super
      # Should apply user's precision setting here   --automatically done, I think
      # Also:  show relative coordinates?
      Sketchup.set_status_text("Select a point to insert the Output:Illuminance Map = " + @ip.position.to_s)
      view.tooltip = "New Output:IlluminanceMap"
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
        UI.messagebox "You need to be in a Zone to add an Illuminance Map"
        Sketchup.send_action("selectSelectionTool:")
        return false
      end
      
      Sketchup.active_model.start_operation("Output:IlluminanceMap")
      
      output_illuminance_map = OutputIlluminanceMap.new
      output_illuminance_map.create_input_object
      output_illuminance_map.zone = this_zone
      output_illuminance_map.sketchup_min = @ip.position
      output_illuminance_map.reset_lengths
      output_illuminance_map.draw_entity 

      Sketchup.active_model.selection.clear
      Sketchup.active_model.selection.add(output_illuminance_map.entity)
 
      Sketchup.send_action("selectScaleTool:")
 
      Sketchup.active_model.commit_operation

    end

  end

end
