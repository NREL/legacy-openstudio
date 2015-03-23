# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/dialogs/DialogInterface")
require("legacy_openstudio/lib/dialogs/PreferencesDialog")


module LegacyOpenStudio

  class PreferencesInterface < DialogInterface

    def initialize
      super
      @dialog = PreferencesDialog.new(nil, self, @hash)
    end


    def populate_hash
    
      # Another interesting way if the automatic conversion between string and boolean doesn't work out
      #@hash['SHOW_DRAWING'] = Plugin.read_pref("Show Drawing") ? "true" : "false" 

      @hash['INTERZONE_SURFACES'] = Plugin.read_pref("Interzone Surfaces Behavior")
      @hash['PROJECT_SUB_SURFACES'] = Plugin.read_pref("Project Sub Surfaces")
      @hash['CHECK_FOR_UPDATE'] = Plugin.read_pref("Check For Update")
      @hash['ERASE_ENTITIES'] = Plugin.read_pref("Erase Entities")
      @hash['CACHE_ESO_RESULTS'] = Plugin.read_pref("Cache Eso Results")
      @hash['SHOW_DRAWING'] = Plugin.read_pref("Show Drawing")
      @hash['PLAY_SOUNDS'] = Plugin.read_pref("Play Sounds")
      @hash['ZOOM_EXTENTS'] = Plugin.read_pref("Zoom Extents")
      @hash['ON_COORD_SYSTEM_CHANGE'] = Plugin.read_pref("On Coordinate System Change")
      @hash['SERVER_TIMEOUT'] = Plugin.read_pref("Server Timeout")
      @hash['TEXT_EDITOR_PATH'] = Plugin.read_pref("Text Editor Path")
      @hash['EXE_PATH'] = Plugin.read_pref("EnergyPlus Path")

    end


    def report

      path = @hash['TEXT_EDITOR_PATH']
      # Should filter out any arguments that get passed for line number, etc.
      # For example:  textpad.exe -l%1 -p
      if (not path.empty? and not File.exists?(path))
        UI.messagebox("WARNING:  Bad file path for the text editor.")
      end

      path = @hash['EXE_PATH']
      if (path.nil? or path.empty?)  # why is path ever nil?
        # Do nothing

      elsif (not File.exists?(path))
        UI.messagebox("WARNING:  Bad file path for the EnergyPlus engine.")

      else
        idd_path = File.dirname(path) + "/Energy+.idd"
        if (not File.exists?(idd_path))
          UI.messagebox("WARNING:  Cannot locate the input data dictionary (IDD) in the EnergyPlus directory.")
          #@hash['EXE_PATH'] = Plugin.read_pref("EnergyPlus Path")
          #@dialog.update
          #return(false)
        else
          user_version = DataDictionary.version(idd_path)
          if (user_version != Plugin.energyplus_version)
            UI.messagebox("WARNING:  The EnergyPlus engine you have specified is version " + user_version + ".  The plugin is designed for version " +
              Plugin.energyplus_version + ".\nThere might be problems with compatibility. Try updating your EnergyPlus engine if there are a lot of simulation errors.")
          end
        end
      end

      # Another interesting way if the automatic conversion between string and boolean doesn't work out
      #Plugin.write_pref("Show Drawing", @hash['SHOW_DRAWING'] == "true" ? true : false)

      Plugin.write_pref("Interzone Surfaces Behavior", @hash['INTERZONE_SURFACES'])
      Plugin.write_pref("Project Sub Surfaces", @hash['PROJECT_SUB_SURFACES'])
      Plugin.write_pref("Check For Update", @hash['CHECK_FOR_UPDATE'])
      Plugin.write_pref("Erase Entities", @hash['ERASE_ENTITIES'])
      Plugin.write_pref("Cache Eso Results", @hash['CACHE_ESO_RESULTS'])
      Plugin.write_pref("Show Drawing", @hash['SHOW_DRAWING'])
      Plugin.write_pref("Play Sounds", @hash['PLAY_SOUNDS'])
      Plugin.write_pref("Zoom Extents", @hash['ZOOM_EXTENTS'])
      Plugin.write_pref("On Coordinate System Change", @hash['ON_COORD_SYSTEM_CHANGE'])
      Plugin.write_pref("Server Timeout", @hash['SERVER_TIMEOUT'])
      Plugin.write_pref("Text Editor Path", @hash['TEXT_EDITOR_PATH'])
      Plugin.write_pref("EnergyPlus Path", @hash['EXE_PATH'])
      
      return(true)
    end

  end

end
