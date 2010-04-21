# OpenStudio
# Copyright (c) 2008-2010, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("OpenStudio/lib/interfaces/DrawingUtils")

module OpenStudio

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
