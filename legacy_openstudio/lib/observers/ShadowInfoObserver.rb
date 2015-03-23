# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/AsynchProc")


module LegacyOpenStudio

  class ShadowInfoObserver < Sketchup::ShadowInfoObserver

    def initialize(drawing_interface)
      @drawing_interface = drawing_interface  # This is the Location drawing interface
      @shadow_time = Sketchup.active_model.shadow_info['ShadowTime']
    end


    def onShadowInfoChanged(shadow_info, arg2)
      # arg2 is a flag that returns 1 when shadows are displayed.

      AsynchProc.new {
        # Turn on Daylight Saving Time.  Appears that SketchUp does not automatically turn it on.
        if (shadow_info.time.dst?)
          shadow_info['DaylightSavings'] = true
        else
          shadow_info['DaylightSavings'] = false
        end

        @drawing_interface.on_change_entity

        if (@shadow_time != Sketchup.active_model.shadow_info['ShadowTime'])
          @shadow_time = Sketchup.active_model.shadow_info['ShadowTime']
          # Would be better to call a method like 'on_time_changed', not necessary to repaint everytime.
          Plugin.model_manager.paint
        end
      }
      
    end

  end
  
end
