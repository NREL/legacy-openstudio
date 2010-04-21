# OpenStudio
# Copyright (c) 2008-2010, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("OpenStudio/lib/dialogs/DialogInterface")

require("OpenStudio/lib/dialogs/BuildingInfoInterface")
require("OpenStudio/lib/dialogs/ZoneInfoInterface")
require("OpenStudio/lib/dialogs/BaseSurfaceInfoInterface")
require("OpenStudio/lib/dialogs/SubSurfaceInfoInterface")
require("OpenStudio/lib/dialogs/AttachedShadingSurfaceInfoInterface")
require("OpenStudio/lib/dialogs/DetachedShadingGroupInfoInterface")
require("OpenStudio/lib/dialogs/DetachedShadingSurfaceInfoInterface")
require("OpenStudio/lib/dialogs/OutputIlluminanceMapInfoInterface")
require("OpenStudio/lib/dialogs/DaylightingControlsInfoInterface")
require("OpenStudio/lib/dialogs/NoSelectionInfoInterface")

require("OpenStudio/lib/dialogs/ObjectInfoDialog")


module OpenStudio

  class ObjectInfoInterface < DialogInterface
  
    def initialize(container = nil)
      super
      @dialog = ObjectInfoDialog.new(nil, self, @hash)
    end


    def populate_hash
      case (drawing_interface_class_name = Plugin.model_manager.selected_drawing_interface.class.to_s)

      when "OpenStudio::Building"
        @active_interface = BuildingInfoInterface.new
        @hash = @active_interface.hash

      when "OpenStudio::Zone"
        @active_interface = ZoneInfoInterface.new
        @hash = @active_interface.hash

      when "OpenStudio::BaseSurface"
        @active_interface = BaseSurfaceInfoInterface.new
        @hash = @active_interface.hash

      when "OpenStudio::SubSurface"
        @active_interface = SubSurfaceInfoInterface.new
        @hash = @active_interface.hash

      when "OpenStudio::AttachedShadingSurface"
        @active_interface = AttachedShadingSurfaceInfoInterface.new
        @hash = @active_interface.hash

      when "OpenStudio::DetachedShadingGroup"
        @active_interface = DetachedShadingGroupInfoInterface.new
        @hash = @active_interface.hash

      when "OpenStudio::DetachedShadingSurface"
        @active_interface = DetachedShadingSurfaceInfoInterface.new
        @hash = @active_interface.hash
        
      when "OpenStudio::OutputIlluminanceMap"
        @active_interface = OutputIlluminanceMapInfoInterface.new
        @hash = @active_interface.hash
        
      when "OpenStudio::DaylightingControls"
        @active_interface = DaylightingControlsInfoInterface.new
        @hash = @active_interface.hash
        
      else  # NilClass
        @active_interface = NoSelectionInfoInterface.new
        @hash = Hash.new
        @hash['OBJECT_TEXT'] = ""

      end

      @hash['CLASS'] = drawing_interface_class_name  # This is how the Dialog knows what its working with
    end


    def report
      if (@active_interface.report)
        @dialog.update
        return(true)
      else
        return(false)
      end
    end
    
  end

end
