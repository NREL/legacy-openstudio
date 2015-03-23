# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/dialogs/Dialogs")


module LegacyOpenStudio

  class NoSelectionInfoPage < Page

    def on_load
      # Don't set the background color because it causes the dialog to flash.
      #@container.execute_function("setBackgroundColor('" + default_dialog_color + "')")
      update_units
      update
    end

  end

end
