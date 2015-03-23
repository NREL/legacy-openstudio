# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/dialogs/Dialogs")
require("legacy_openstudio/lib/dialogs/DialogContainers")


module LegacyOpenStudio

  class PreferencesDialog < PropertiesDialog

    def initialize(container, interface, hash)
      super
      w = Plugin.platform_select(537, 600)
      h = Plugin.platform_select(346, 430)
      @container = WindowContainer.new("Preferences", w, h, 150, 150)
      @container.set_file(Plugin.dir + "/lib/dialogs/html/Preferences.html")

      add_callbacks
    end


    def add_callbacks
      super
      @container.web_dialog.add_action_callback("on_browse_text_editor") { browse_text_editor }
      @container.web_dialog.add_action_callback("on_browse_exe") { browse_exe }
    end


    def browse_text_editor
      path = @hash['TEXT_EDITOR_PATH']

      if (path.nil? or path.empty?)
        path = Plugin.default_preferences['Text Editor Path']
      end

      dir = File.dirname(path)
      file_name = File.basename(path)

      if (not File.exist?(dir))
        dir = ""
      end

      if (path = UI.open_panel("Locate Text Editor Program", dir, file_name))
        path = path.split("\\").join("/")  # Have to convert the file separator for other stuff to work later
        # Above is a kludge...should allow any separators to be cut and paste into the text box
        @hash['TEXT_EDITOR_PATH'] = path
        update
      end
    end


    def browse_exe
      path = @hash['EXE_PATH']

      if (path.nil? or path.empty?)
        path = Plugin.default_preferences['EnergyPlus Path']
      end

      dir = File.dirname(path)
      file_name = File.basename(path)

      if (not File.exist?(dir))
        dir = ""
      end

      if (path = UI.open_panel("Locate EnergyPlus Program", dir, file_name))
        path = path.split("\\").join("/")  # Have to convert the file separator for other stuff to work later
        # Above is a kludge...should allow any separators to be cut and paste into the text box

        @hash['EXE_PATH'] = path
        update
      end
    end

  end
  
end
