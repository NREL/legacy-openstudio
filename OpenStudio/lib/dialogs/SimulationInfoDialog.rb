# OpenStudio
# Copyright (c) 2008-2011, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("OpenStudio/lib/dialogs/Dialogs")
require("OpenStudio/lib/dialogs/DialogContainers")


module OpenStudio

  
  class SimulationInfoDialog < PropertiesDialog

    def initialize(container, interface, hash)
      super
      w = Plugin.platform_select(400, 430)
      h = Plugin.platform_select(400, 445)
      @container = WindowContainer.new("Simulation Info", w, h, 150, 150)
      @container.set_file(Plugin.dir + "/lib/dialogs/html/SimulationInfo.html")

      add_callbacks
    end
    
    def on_load
      super
      #disable_element("COORDINATE_SYSTEM")
      #disable_element("DAYLIGHTING_COORDINATE_SYSTEM")
      #disable_element("RECTANGULAR_COORDINATE_SYSTEM")
      #disable_element("VERTEX_ORDER")
      #disable_element("STARTING_VERTEX")
    end 

  end
  
end
