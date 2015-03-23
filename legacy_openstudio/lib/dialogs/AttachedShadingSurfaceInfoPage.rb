# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/dialogs/Dialogs")


module LegacyOpenStudio

  class AttachedShadingSurfaceInfoPage < Page

    def add_callbacks
      super
      @container.web_dialog.add_action_callback("on_change_element") { |d, p| on_change_element(d, p) }
    end


    def on_load
      #super

      # Populate base surface list
      object_names = Plugin.model_manager.input_file.find_objects_by_class_name("BUILDINGSURFACE:DETAILED").collect { |object| object.name }
      if (not object_names.contains?(@hash['BASE_SURFACE']))
        object_names.add(@hash['BASE_SURFACE'])
      end
      set_select_options("BASE_SURFACE", object_names.sort)

      # Populate transmittance schedule list
      object_names = Plugin.model_manager.input_file.find_objects_by_class_name("SCHEDULE:YEAR", "SCHEDULE:COMPACT", "SCHEDULE:FILE").collect { |object| object.name }
      if (not object_names.contains?(@hash['TRANSMITTANCE'])) and  @hash['TRANSMITTANCE'] != ""
        object_names.add(@hash['TRANSMITTANCE'])
      end
      set_select_options("TRANSMITTANCE", [""].concat(object_names.sort))

      #super

      # Don't set the background color because it causes the dialog to flash.
      #@container.execute_function("setBackgroundColor('" + default_dialog_color + "')")
      update_units
      update
    end


    def on_change_element(d, p)
      super
      report
    end

  end

end
