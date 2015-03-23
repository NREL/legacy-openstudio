# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

module LegacyOpenStudio

  class UpdateManager
  
    def initialize
      @web_dialog = nil
      @url = "http://openstudio.sourceforge.net/update.html"
      @timer = nil
      @version = nil
    end

    def check_for_update(verbose = true)

      puts "Checking for update..."

      #if (Sketchup.is_online)  # doesn't work

      @web_dialog = UI::WebDialog.new("", false, Plugin.name + " - Check For Updates", 0, 0, 0, 0, false)
      # TIP:  0 width and height makes the dialog invisible; must have resize set to false also

      @web_dialog.add_action_callback("on_load") { on_load(verbose) }
      @web_dialog.set_url(@url)
      @web_dialog.show

      # if page doesn't load in 5 seconds pop up dialog
      @timer = UI.start_timer(5, false) { 
        if (verbose)
          button = UI.messagebox(Plugin.name + " was unable to connect to the update server.\nCheck your internet connection and try again later.", MB_RETRYCANCEL)
          if (button == 4)
            check_for_update
          else
            close_web_dialog
          end
        else
          close_web_dialog
        end
      }
      return(nil)
    end


    def on_load(verbose)
      
      if @timer
        UI.stop_timer(@timer)
      end
      
      @version = @web_dialog.get_element_value("version")
      close_web_dialog

      puts "Current version=" + Plugin.version
      puts "Most recent version=" + @version

      # Kludge:  Give a very brief delay to allow the WebDialog to fully close.
      @second_timer = UI.start_timer(1, false) {
      
        if @second_timer
          UI.stop_timer(@second_timer)
        end
        
        # Version numbering scheme is (major).(minor).(maintenance).(build), e.g. 0.9.4.1
        installed_version_key = ''; Plugin.version.split('.').each { |e| installed_version_key += e.rjust(4, '0') }
        newest_version_key = ''; @version.split('.').each { |e| newest_version_key += e.rjust(4, '0') }
        skip_version_key = Plugin.read_pref('Skip Update')
      
        if (installed_version_key < newest_version_key)
          if (newest_version_key != skip_version_key or verbose)
            button = UI.messagebox("A newer version (" + @version + ") of OpenStudio is ready for download.\n" +
              "Do you want to update to the newer version?\n\n" +
              "Click YES to visit the OpenStudio website to get the download.\n" +
              "Click NO to skip this version and not ask you again.\n" +
              "Click CANCEL to remind you again next time.", MB_YESNOCANCEL)
            if (button == 6)  # YES
              # Annoying quirk of UI.openURL is that it will hijack any open browser window.
              UI.openURL("http://www.energyplus.gov/openstudio.cfm")
            elsif (button == 7)  # NO
              Plugin.write_pref('Skip Update', newest_version_key)
            end
          end
        elsif (verbose)
          UI.messagebox("You currently have the most recent version of OpenStudio.")
        end
      }
    end


    def close_web_dialog
      if (@web_dialog and @web_dialog.visible?)
        @web_dialog.close
      end
    end

  end

end
