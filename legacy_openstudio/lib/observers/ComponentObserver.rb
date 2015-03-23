# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/interfaces/DrawingUtils")

module LegacyOpenStudio

  class ComponentObserver < Sketchup::EntityObserver

    def initialize(drawing_interface)
      @drawing_interface = drawing_interface
    end

    def onChangeEntity(entity)
      @drawing_interface.on_change_entity
    end

    def onEraseEntity(entity)
      @drawing_interface.on_erase_entity
    end

  end

end
