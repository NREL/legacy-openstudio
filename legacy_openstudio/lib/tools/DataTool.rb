# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/tools/Tool")


module LegacyOpenStudio

  class DataTool < Tool

    def initialize
      @cursor = UI.create_cursor(Plugin.dir + "/lib/resources/icons/DataToolCursor-16x17.tiff", 1, 1)
    end


    def onMouseMove(flags, x, y, view)
      super

      if (v = @ip.vertex)
        #Sketchup.set_status_text("World Coordinates:  " + v.position.to_s)
      else
        
        if (face = @ip.face)
          if (drawing_interface = face.drawing_interface)

            # Determine if the camera is looking at the inside or outside of the face
            pickray = view.pickray(x, y)
            #point = pickray[0]
            vector = pickray[1]

            if (vector % face.normal < 0.0)  # Outside
              variable_def = drawing_interface.outside_variable_def
              value = drawing_interface.outside_value
            else  # Inside
              variable_def = drawing_interface.inside_variable_def
              value = drawing_interface.inside_value
            end

            if (variable_def.nil? or value.nil?)
              tooltip = " No data."  # Extra space to get out from under the icon
            else
              tooltip = variable_def.object_name + "\n"
              tooltip += variable_def.set_name + "\n"
              tooltip += value.round_to(Plugin.model_manager.length_precision).to_s + " " + variable_def.units
              
              if (Plugin.model_manager.results_manager.normalize)
                if (Plugin.model_manager.units_system == "SI")
                  tooltip += "/m2"
                else
                  tooltip += "/ft2"
                end
              end

              if (Plugin.model_manager.results_manager.interpolate)
                tooltip += " <Interpolated>"
              end
            end

          else
            tooltip = "No EnergyPlus object found."
          end
        else
          tooltip = ""  
        end

        view.tooltip = tooltip
      end
      
    end

  end

end
