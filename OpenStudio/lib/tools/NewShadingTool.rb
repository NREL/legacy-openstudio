# OpenStudio
# Copyright (c) 2008-2009 Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("OpenStudio/lib/interfaces/DetachedShadingGroup")
require("OpenStudio/lib/tools/NewGroupTool")


module OpenStudio

  class NewShadingTool < NewGroupTool

    def onMouseMove(flags, x, y, view)
      super
      Sketchup.set_status_text("Select a point to become the New Shading Group")
      view.tooltip = "New Shading Group"
    end


    def onLButtonUp(flags, x, y, view)
      super

      Sketchup.active_model.start_operation("Shading Group")

      shading_group = DetachedShadingGroup.new
      shading_group.origin = @ip.position
      shading_group.show_origin = true
      shading_group.draw_entity

      Sketchup.active_model.selection.add(shading_group.entity)

      # Always want to end with the Selection Tool so users can double-click the new shading group.
      Sketchup.send_action("selectSelectionTool:")

      Sketchup.active_model.commit_operation
    end
    
  end

end
