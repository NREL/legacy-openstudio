# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/tools/Tool")


module LegacyOpenStudio

  class NewGroupTool < Tool

    def initialize
      @cursor = UI.create_cursor(Plugin.dir + "/lib/resources/icons/OriginToolCursor-14x20.tiff", 3, 3)
    end


    def activate
      super
      Sketchup.active_model.selection.clear
    end

  end

end
