# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/AsynchProc")


module LegacyOpenStudio

  # This class is used for both Zone Groups and Detached Shading Groups.
  class SurfaceGroupObserver < Sketchup::EntityObserver

    def initialize(drawing_interface)
      @drawing_interface = drawing_interface
    end


    # Group was moved, scaled, or rotated.
    # Note that onChangeEntity is NOT triggered for the enclosed entities!
    # Vertices of the enclosed entities DO NOT change...instead a transformation is applied to the Group.
    def onChangeEntity(entity)
      #puts "SurfaceGroupObserver.onChangeEntity:" + entity.to_s

      # Asynchronous proc is required, otherwise only the first onChangeEntity is fired for some reason.
      AsynchProc.new {
        #puts "group proc"

        # When a group is erased, one last call to 'onChangeEntity' is still issued.
        if (@drawing_interface.valid_entity?)
          @drawing_interface.on_change_entity
        end
      }
    end


    # Group was erased or otherwise deleted.
    # onEraseEntity IS subsequently triggered for the enclosed entities.
    def onEraseEntity(entity)
      #puts "SurfaceGroupObserver.onEraseEntity:" + entity.to_s

      AsynchProc.new {
        @drawing_interface.on_erase_entity
      }
    end

  end


end
