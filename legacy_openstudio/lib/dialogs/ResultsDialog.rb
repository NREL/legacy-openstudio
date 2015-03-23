# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/dialogs/Dialogs")
require("legacy_openstudio/lib/dialogs/DialogContainers")


module LegacyOpenStudio

  class ResultsDialog < MessageDialog

    def initialize(interface, hash)
      super
      @container = WindowContainer.new("Simulation Results", 585, 600, 50, 50)
      @container.set_file(Plugin.dir + "/lib/dialogs/html/ResultsChart.html")

      add_callbacks
    end


    def add_callbacks
      super
      @container.web_dialog.add_action_callback("on_abups") { on_abups }
    end


    def on_load
      super
      script = "drawChart(" + $results.inspect + ")"
      # drawChart cannot handle 0.0!!!
    
      @container.web_dialog.execute_script(script)
    end


    def on_abups
      abups = UI::WebDialog.new("Annual Building Utility Performance Summary (ABUPS)", true, "EnergyPlus ABUPS", 400, 400, 50, 50, true)
      abups.show  # Bug Workaround:  show must be called before set_file or else scroll bars do not get drawn!
      abups.set_file(File.dirname(Plugin.energyplus_path) + "/eplustbl.htm", nil)
      #abups.show

      $abups = abups  # need this reference to keep the dialog alive...otherwise it gets garbage collected
    end

  end

end
