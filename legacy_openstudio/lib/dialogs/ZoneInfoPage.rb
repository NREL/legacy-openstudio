# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/dialogs/Dialogs")


module LegacyOpenStudio

  class ZoneInfoPage < Page
  
    def add_callbacks
      super
      @container.web_dialog.add_action_callback("on_change_element") { |d, p| on_change_element(d, p) }
    end


    def on_load
      # Don't set the background color because it causes the dialog to flash.
      #@container.execute_function("setBackgroundColor('" + default_dialog_color + "')")
      update_units
      update
      #disable_element("ROTATION")
    end


    def on_change_element(d, p)
      super
      report
    end

  end

end
