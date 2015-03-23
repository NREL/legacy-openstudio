# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/dialogs/Dialogs")
require("legacy_openstudio/lib/dialogs/DialogContainers")


module LegacyOpenStudio

  class FileInfoDialog < MessageDialog

    def initialize(container, interface, hash)
      super
      h = Plugin.platform_select(363, 395)
      @container = WindowContainer.new("File Info", 615, h, 150, 150)
      @container.set_file(Plugin.dir + "/lib/dialogs/html/FileInfo.html")

      add_callbacks
    end


    def add_callbacks
      super
      @container.web_dialog.add_action_callback("on_view_idf") { view_idf }
    end


    def view_idf
      # Not used right now
      
      editor_path = Plugin.read_pref("Text Editor Path")
      file_path = Plugin.model_manager.input_file.path
      
      if (not editor_path.nil? and not file_path.nil?)
        command_string = '"' + editor_path + '" "' + file_path + '"'

        # Need different command for Mac OSX        
        UI.shell_command(command_string)
        
        #UI.openURL('file://"' + editor_path + '" "' + file_path + '"')
      else
        puts "missing editor path or file path"
      end
    end

  end
  
end
