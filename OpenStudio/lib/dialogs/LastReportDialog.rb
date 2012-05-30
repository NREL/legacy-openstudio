# OpenStudio
# Copyright (c) 2008-2012, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("OpenStudio/lib/dialogs/Dialogs")
require("OpenStudio/lib/dialogs/DialogContainers")


module OpenStudio

  class LastReportDialog < MessageDialog

    def initialize(container, interface, hash)
      super
      @container = WindowContainer.new(Plugin.name + " Last Report Window", 400, 400, 150, 150)
      @container.center_on_parent
      @container.set_file(Plugin.dir + "/lib/dialogs/html/LastReport.html")
      
      add_callbacks
    end
    
    def on_load
      super
    end
    
    def update
      super
    end

  end

end
