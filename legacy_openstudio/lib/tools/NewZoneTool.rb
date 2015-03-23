# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/interfaces/Zone")
require("legacy_openstudio/lib/tools/NewGroupTool")


module LegacyOpenStudio

  class NewZoneTool < NewGroupTool

    def onMouseMove(flags, x, y, view)
      super
      # Should apply user's precision setting here   --automatically done, I think
      # Also:  show relative coordinates?
      Sketchup.set_status_text("Select a point to become the New Zone Origin = " + @ip.position.to_s)
      view.tooltip = "New Zone"
    end


    def onLButtonUp(flags, x, y, view)
      super
      
      model = Sketchup.active_model
      active_path = model.active_path

      if not active_path.nil?
        UI.messagebox("Zone should be added at the top level of a SketchUp model")
        Sketchup.send_action("selectSelectionTool:")
        return false
      end

      Sketchup.active_model.start_operation("Zone")

      zone = Zone.new
      zone.create_input_object
      zone.origin = @ip.position
      zone.show_origin = true
      zone.draw_entity

      Sketchup.active_model.selection.add(zone.entity)

      # Always want to end with the Selection Tool so users can double-click the new zone.
      Sketchup.send_action("selectSelectionTool:")

      Sketchup.active_model.commit_operation
    end

  end

end
