# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/dialogs/Dialogs")
require("legacy_openstudio/lib/dialogs/DialogContainers")


module LegacyOpenStudio

  class ColorScaleDialog < Dialog

    def initialize(container, interface, hash)
      super
      h = Plugin.platform_select(370, 395)
      @container = WindowContainer.new("", 112, h, 150, 150)
      @container.set_file(Plugin.dir + "/lib/dialogs/html/ColorScale.html")
      add_callbacks
    end


    def on_load
      super

      if (Plugin.platform == Platform_Mac)
        @container.execute_function("invalidate()")  # Force the WebDialog to redraw
      end
    end


    def update
      super
      if (Plugin.model_manager.results_manager.rendering_appearance == "COLOR")
        set_element_source("COLOR_SCALE", "colorscale_vertical.bmp")
      else
        set_element_source("COLOR_SCALE", "grayscale_vertical.bmp")
      end
    end

  end
  
end
