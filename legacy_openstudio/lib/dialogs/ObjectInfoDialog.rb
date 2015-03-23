# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/dialogs/Dialogs")
require("legacy_openstudio/lib/dialogs/DialogContainers")

require("legacy_openstudio/lib/dialogs/BuildingInfoPage")
require("legacy_openstudio/lib/dialogs/ZoneInfoPage")
require("legacy_openstudio/lib/dialogs/BaseSurfaceInfoPage")
require("legacy_openstudio/lib/dialogs/SubSurfaceInfoPage")
require("legacy_openstudio/lib/dialogs/AttachedShadingSurfaceInfoPage")
require("legacy_openstudio/lib/dialogs/DetachedShadingGroupInfoPage")
require("legacy_openstudio/lib/dialogs/DetachedShadingSurfaceInfoPage")
require("legacy_openstudio/lib/dialogs/OutputIlluminanceMapInfoPage")
require("legacy_openstudio/lib/dialogs/DaylightingControlsInfoPage")
require("legacy_openstudio/lib/dialogs/NoSelectionInfoPage")


module LegacyOpenStudio

  class ObjectInfoDialog < PropertiesDialog

    attr_accessor :container

    def initialize(container, interface, hash)
      super

      if (container.nil?)
        @container = WindowContainer.new("Object Info", 480, 600, 150, 150)
      else
        @container = container  # will never happen
      end

      @container.show

      @container.set_file(Plugin.dir + "/lib/dialogs/html/ObjectInfo.html")

      @building_frame = FrameContainer.new(@container, "BUILDING_FRAME")
      @zone_frame = FrameContainer.new(@container, "ZONE_FRAME")
      @base_surface_frame = FrameContainer.new(@container, "BASE_SURFACE_FRAME")
      @sub_surface_frame = FrameContainer.new(@container, "SUB_SURFACE_FRAME")
      @attached_shading_surface_frame = FrameContainer.new(@container, "ATTACHED_SHADING_SURFACE_FRAME")
      @detached_shading_group_frame = FrameContainer.new(@container, "DETACHED_SHADING_GROUP_FRAME")
      @detached_shading_surface_frame = FrameContainer.new(@container, "DETACHED_SHADING_SURFACE_FRAME")
      @output_illuminance_map_frame = FrameContainer.new(@container, "OUTPUT_ILLUMINANCE_MAP_FRAME")
      @daylighting_controls_frame = FrameContainer.new(@container, "DAYLIGHTING_CONTROLS_FRAME")
      @no_selection_frame = FrameContainer.new(@container, "NO_SELECTION_FRAME")

      add_callbacks
    end


    def on_load
      super

      frame_names = ["BUILDING_FRAME", "ZONE_FRAME", "BASE_SURFACE_FRAME", "SUB_SURFACE_FRAME", "ATTACHED_SHADING_SURFACE_FRAME",
        "DETACHED_SHADING_GROUP_FRAME", "DETACHED_SHADING_SURFACE_FRAME", "OUTPUT_ILLUMINANCE_MAP_FRAME", "DAYLIGHTING_CONTROLS_FRAME",
        "NO_SELECTION_FRAME", "TEXT_FRAME", "FILLER_FRAME"]

      for frame_name in frame_names
        if (Plugin.platform == Platform_Windows)
        # make this a platform-responsive container function...   @container.set_background_color(name)
          @container.execute_function(frame_name + ".setBackgroundColor('" + default_dialog_color + "')")
        else
          @container.execute_function(frame_name + "setBackgroundColor('" + default_dialog_color + "')")
        end
      end

      if (Plugin.platform == Platform_Mac)
        @container.execute_function("invalidate()")  # Force the WebDialog to redraw
      end
    end


    def update
      @hash = @interface.hash  # Not sure why I need this

      if (Plugin.platform == Platform_Windows)
        # DISABLED:  This was causing the Object Info to always jump to the foreground when updated.
        #@container.execute_function("FILLER_FRAME.focus()")  # Ensure that all onchange events are triggered
      else
        #@container.execute_function("FILLER_FRAMEfocus()")  # Not sure if this does anything on the Mac
      end

      case (@hash['CLASS'])

      when "LegacyOpenStudio::Building"
        h = Plugin.platform_select('340', '370')
        function_call = "setRows('" + h + "px,0px,0px,0px,0px,0px,0px,0px,0px,0px,*,6px')"
        @info_page = BuildingInfoPage.new(@building_frame, @interface, @hash)

      when "LegacyOpenStudio::Zone"
        h = Plugin.platform_select('273', '292')
        function_call = "setRows('0px," + h + "px,0px,0px,0px,0px,0px,0px,0px,0px,*,6px')"
        @info_page = ZoneInfoPage.new(@zone_frame, @interface, @hash)

      when "LegacyOpenStudio::BaseSurface"
        h = Plugin.platform_select('366', '397')
        function_call = "setRows('0px,0px," + h + "px,0px,0px,0px,0px,0px,0px,0px,*,6px')"
        @info_page = BaseSurfaceInfoPage.new(@base_surface_frame, @interface, @hash)

      when "LegacyOpenStudio::SubSurface"
        h = Plugin.platform_select('367', '404')
        function_call = "setRows('0px,0px,0px," + h + "px,0px,0px,0px,0px,0px,0px,*,6px')"
        @info_page = SubSurfaceInfoPage.new(@sub_surface_frame, @interface, @hash)

      when "LegacyOpenStudio::AttachedShadingSurface"
        h = Plugin.platform_select('189', '210')
        function_call = "setRows('0px,0px,0px,0px," + h + "px,0px,0px,0px,0px,0px,*,6px')"
        @info_page = AttachedShadingSurfaceInfoPage.new(@attached_shading_surface_frame, @interface, @hash)

      when "LegacyOpenStudio::DetachedShadingGroup"
        h = Plugin.platform_select('142', '158')
        function_call = "setRows('0px,0px,0px,0px,0px," + h + "px,0px,0px,0px,0px,*,6px')"
        @info_page = DetachedShadingGroupInfoPage.new(@detached_shading_group_frame, @interface, @hash)

      when "LegacyOpenStudio::DetachedShadingSurface"
        h = Plugin.platform_select('164', '184')
        function_call = "setRows('0px,0px,0px,0px,0px,0px," + h + "px,0px,0px,0px,*,6px')"
        @info_page = DetachedShadingSurfaceInfoPage.new(@detached_shading_surface_frame, @interface, @hash)
        
      when "LegacyOpenStudio::OutputIlluminanceMap"
        h = Plugin.platform_select('280', '340')
        function_call = "setRows('0px,0px,0px,0px,0px,0px,0px," + h + "px,0px,0px,*,6px')"
        @info_page = OutputIlluminanceMapInfoPage.new(@output_illuminance_map_frame, @interface, @hash)
        
      when "LegacyOpenStudio::DaylightingControls"
        h = Plugin.platform_select('480', '520')
        function_call = "setRows('0px,0px,0px,0px,0px,0px,0px,0px," + h + "px,0px,*,6px')"
        @info_page = DaylightingControlsInfoPage.new(@daylighting_controls_frame, @interface, @hash)
        
      else
        h = Plugin.platform_select('300', '336')
        function_call = "setRows('0px,0px,0px,0px,0px,0px,0px,0px,0px," + h + "px,*,6px')"
        @info_page = NoSelectionInfoPage.new(@no_selection_frame, @interface, @hash)
      end

      if (Plugin.platform == Platform_Mac and Sketchup.version.to_i < 7)
        # Kludge for bug with WebDialogs on the Mac in SU6; fixed in SU7.
        function_call.gsub!(/,/, '%comma%')
      end

      @container.execute_function(function_call)
      @info_page.on_load

      value = @hash['OBJECT_TEXT']

      # Repeat some code from Dialog.set_element_value because we're circumventing it with a direct call to execute_function below
      if (Plugin.platform == Platform_Windows)
        value.gsub!(/\n/, "\\n")  # Replace \n with \\n for JavaScript
      elsif (Sketchup.version.to_i < 7)
        # Mac SU6
        value.gsub!(/,/, "%comma%")  # Replace commas with tags for Mac (maybe a SketchUp bug)
      else
        # Mac SU7

        # Handle Posix newlines because the context string in 'to_idf' comes from reading the file.
        # Should probably address this directly in the 'to_idf' method or earlier.
        value.gsub!(/\r\n/, "\\n")  # Replace \r\n (Posix newline) with \\n for JavaScript

        # This one gets triggered the second time around, after \r\n has already been replaced in the OBJECT_TEXT string.
        value.gsub!(/\n/, "\\n")  # Replace \n with \\n for JavaScript

        # "Unfix" a workaround for a bug in SU6 that added an extra space character at the beginning of the string.
        # SU7 corrects that bug, but the Javascript workaround in Dialogs.js still clips the first character.
        value = ' ' + value
      end

      if (Plugin.platform == Platform_Windows or Sketchup.version.to_i > 6)
        # All Windows and Mac SU7
        @container.execute_function("TEXT_FRAME.setElementValue('OBJECT_TEXT', '" + value + "')")
      else
        # Mac SU6
        @container.execute_function("TEXT_FRAMEsetElementValue('OBJECT_TEXT', '" + value + "')")
      end
    end

  end


end
