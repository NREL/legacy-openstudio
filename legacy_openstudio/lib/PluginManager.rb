# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/AnimationManager")
require("legacy_openstudio/lib/AsynchProc")
require("legacy_openstudio/lib/CommandManager")
require("legacy_openstudio/lib/DialogManager")
require("legacy_openstudio/lib/MenuManager")
require("legacy_openstudio/lib/ModelManager")
require("legacy_openstudio/lib/SimulationManager")
require("legacy_openstudio/lib/UpdateManager")
require("legacy_openstudio/lib/inputfile/DataDictionary")

require("legacy_openstudio/sketchup/UI")
require("legacy_openstudio/sketchup/Sketchup")
require("legacy_openstudio/sketchup/Geom")

#UI.messagebox "Starting Plugin!"

module LegacyOpenStudio

  Platform_Unknown = 0
  Platform_Windows = 1
  Platform_Mac = 2

  class PluginManager

    attr_reader :name, :version, :dir, :progress_dialog, :asynch_delay
    
    attr_accessor :data_dictionary, :model_manager, :command_manager, :menu_manager, :dialog_manager, :animation_manager, :simulation_manager, :preferences
    attr_accessor :energyplus_path, :update_manager, :load_components

    def initialize
      @name = OPENSTUDIO_PLUGIN_NAME   
      @version = OPENSTUDIO_PLUGIN_VERSION

      # need safety check here if can't find path!!
      @dir = File.dirname(__FILE__) + "/.."
    end


    def start
      # 'start' must be separate from 'initialize' because some of the objects below are dependent on the Plugin module constant.

      load_default_preferences

      if (open_data_dictionary)
        Sketchup.add_observer(AppObserver.new)  # hopefully can catch creation of model

        @simulation_manager = SimulationManager.new  # Should this really be under ModelManager?
        @animation_manager = AnimationManager.new

        # Any object containing validation procs that are called by GUIManager must be created before GUIManager is created
        # otherwise this method will fail on the Mac (but is okay on Windows).
        @command_manager = CommandManager.new
        @menu_manager = MenuManager.new

        #if (platform == Platform_Windows)
        # Used to not be required on Mac, but as of Leopard it seems to be necessary.
          new_model  # Required for Windows because the AppObserver already missed the onNewModel callback (not so on Mac).
        #end

        @dialog_manager = DialogManager.new
      end

      @update_manager = UpdateManager.new

      if (Plugin.read_pref("Check For Update") and platform == Platform_Windows)
        # Kludge:  Give a delay to allow SketchUp to finish starting up, otherwise can BugSplat.
        AsynchProc.new(2000) { @update_manager.check_for_update(false) }
      end
    end


    def do_bug
      # For testing ErrorHandler
      
      $test = false
      
      a = nil
      b = a + 3
    end


    def inspect
      return(to_s)
    end


    def open_data_dictionary
      success = false
      idd_path = Plugin.dir + "/Energy+.idd"

      if (File.exists?(idd_path))
        @data_dictionary = DataDictionary.open(idd_path)
        success = true
      else
        UI.messagebox("Cannot locate the Data Dictionary file Energy+.idd.\nOpenStudio will not be loaded.")
        puts "Bad IDD path=" + idd_path
      end

      return(success)
    end


    def platform
      # Could change this to a module method.

      if (RUBY_PLATFORM =~ /mswin/ || RUBY_PLATFORM =~ /mingw/)  # Windows
        return(Platform_Windows)
      elsif (RUBY_PLATFORM =~ /darwin/)  # Mac OS X
        return(Platform_Mac)
      else
        return(Platform_Unknown)
      end
    end


    def platform_select(win = nil, mac = win)
      # Could change this to a module method.

      if (RUBY_PLATFORM =~ /mswin/ || RUBY_PLATFORM =~ /mingw/)  # Windows
        return(win)
      elsif (RUBY_PLATFORM =~ /darwin/)  # Mac OS X
        return(mac)
      else
        return(win)
      end
    end


    def new_model
      @model_manager = ModelManager.new
      @model_manager.start
      ObjectSpace.garbage_collect
    end


    def read_pref(name)
      return(Sketchup.read_default("OpenStudio", name))
    end


    def write_pref(name, value)
      Sketchup.write_default("OpenStudio", name, value)
    end


    def default_preferences
      hash = Hash.new
      hash['Interzone Surfaces Behavior'] = "SET_BOUNDARY_CONDITIONS"
      hash['Project Sub Surfaces'] = true
      hash['Check For Update'] = true
      hash['Skip Update'] = ""
      hash['Erase Entities'] = false
      hash['Cache Eso Results'] = true
      hash['Show Drawing'] = false
      hash['Play Sounds'] = true
      hash['Zoom Extents'] = true
      hash['On Coordinate System Change'] = "Always Ask User"
      hash['Server Timeout'] = "120"
      hash['Last Input File Dir'] = Plugin.dir
      hash['Open Dialogs'] = ""
      
      if (platform == Platform_Windows)
        hash['Text Editor Path'] = "C:/WINDOWS/system32/notepad.exe"
        hash['EnergyPlus Path'] = "C:/EnergyPlusV8-1-0/EnergyPlus.exe"  # Default installation path
      elsif (platform == Platform_Mac)
        hash['Text Editor Path'] = "/Applications/TextEdit.app"
        hash['EnergyPlus Path'] = "/Applications/EnergyPlus-8-1-0/energyplus"  # Default installation path
        hash['Check For Update'] = false
      end

      return(hash)
    end


    # Create and set default preferences for any that might not be in the Registry already.
    # For example, the first time the plugin is run, or the first time a new version (with new preferences) is run.
    # Stores values in the Registry at:  HKEY_CURRENT_USER/Software/Google/SketchUp6/OpenStudio   
    def load_default_preferences
      default_hash = default_preferences
      for key in default_hash.keys
        if (read_pref(key).nil?)
          write_pref(key, default_hash[key])
        end
      end
    end


    def energyplus_path
      return(read_pref("EnergyPlus Path"))
    end


    def energyplus_dir
      # Still not sure if this should be made available
      return(File.dirname(energyplus_path))
    end


    def energyplus_version
      return('8.4.0')
    end

  end


  # Create a module constant to reference the plugin object anywhere within the module.
  Plugin = PluginManager.new
  Plugin.start
  $p = Plugin

end
