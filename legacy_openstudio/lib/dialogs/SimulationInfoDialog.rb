# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/dialogs/Dialogs")
require("legacy_openstudio/lib/dialogs/DialogContainers")


module LegacyOpenStudio

  
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
