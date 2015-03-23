# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/dialogs/DialogInterface")


module LegacyOpenStudio

  class DetachedShadingGroupInfoInterface < DialogInterface

    def populate_hash

      @drawing_interface = Plugin.model_manager.selected_drawing_interface

      if (not @drawing_interface.nil?)

        if (@drawing_interface.surface_type == 0)
          @hash['TYPE'] = "FIXED"
        else
          @hash['TYPE'] = "BUILDING"
        end

        # Need better method here
        if (Plugin.model_manager.units_system == "SI")
          i = 0
          surface_area = @drawing_interface.area.to_m.to_m
        else
          i = 1
          surface_area = @drawing_interface.area.to_feet.to_feet
        end

        @hash['SURFACES'] = @drawing_interface.children.count
        @hash['SURFACE_AREA'] = surface_area.round_to(Plugin.model_manager.length_precision).to_s + " " + Plugin.model_manager.units_hash['m2'][i]

        @hash['OBJECT_TEXT'] = ""
      end

    end


    def report
      if (@hash['TYPE'] == "FIXED")
        @drawing_interface.surface_type = 0
      else
        @drawing_interface.surface_type = 1
      end

      # Update drawing interface
      @drawing_interface.on_change_input_object

      return(true)
    end
    

  end

end
