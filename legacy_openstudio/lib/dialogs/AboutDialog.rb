# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/dialogs/Dialogs")
require("legacy_openstudio/lib/dialogs/DialogContainers")


module LegacyOpenStudio

  class AboutDialog < MessageDialog

    def initialize(container, interface, hash)
      super
      @container = WindowContainer.new(Plugin.name, 360, 480, 150, 150, false, false)
      @container.center_on_parent
      @container.set_file(Plugin.dir + "/lib/dialogs/html/About.html")

      add_callbacks
    end


    def show
      @container.show_modal    
    end

  end

end
