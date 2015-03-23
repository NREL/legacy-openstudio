# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/dialogs/Dialogs")


module LegacyOpenStudio

  class DaylightingControlsInfoPage < Page

    def add_callbacks
      super
      @container.web_dialog.add_action_callback("on_change_element") { |d, p| on_change_element(d, p) }
    end


    def on_load
      #super

      # Don't set the background color because it causes the dialog to flash.
      #@container.execute_function("setBackgroundColor('" + default_dialog_color + "')")
      update_units
      update
      update_elements
    end


    def on_change_element(d, p)
      super
      update_elements
      report
    end
    
    
    def update_elements
      
      num_points = @hash['NUMPOINTS'].to_i
      if num_points == 1
        disable_element('X2')
        disable_element('Y2')
        disable_element('Z2')
        disable_element('FRAC2')
        disable_element('SETPOINT2')
      else
        enable_element('X2')
        enable_element('Y2')
        enable_element('Z2')
        enable_element('FRAC2')
        enable_element('SETPOINT2')
      end
    end

  end

end
