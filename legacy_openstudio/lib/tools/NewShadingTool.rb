# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/interfaces/DetachedShadingGroup")
require("legacy_openstudio/lib/tools/NewGroupTool")


module LegacyOpenStudio

  class NewShadingTool < NewGroupTool

    def onMouseMove(flags, x, y, view)
      super
      Sketchup.set_status_text("Select a point to become the New Shading Group")
      view.tooltip = "New Shading Group"
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
      
      model.start_operation("Shading Group")

      shading_group = DetachedShadingGroup.new
      shading_group.origin = @ip.position
      shading_group.show_origin = true
      shading_group.draw_entity

      model.selection.add(shading_group.entity)

      # Always want to end with the Selection Tool so users can double-click the new shading group.
      Sketchup.send_action("selectSelectionTool:")

      Sketchup.active_model.commit_operation
    end
    
  end

end
