# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/tools/Tool")


module LegacyOpenStudio

  class OriginTool < Tool

    def initialize
      @cursor = UI.create_cursor(Plugin.dir + "/lib/resources/icons/OriginToolCursor-14x20.tiff", 3, 10)
    end


    def onMouseMove(flags, x, y, view)
      super
      
      # Should apply user's precision setting here   --automatically done, I think
      # Also:  show relative coordinates?
      Sketchup.set_status_text("Set Zone Origin = " + @ip.position.to_s)
      
      view.tooltip = "Set Zone Origin"
    end


    def onLButtonUp(flags, x, y, view)
      super
      
      # set the origin on the zone object
      
      Sketchup.active_model.tools.pop_tool
    end

  end


end
