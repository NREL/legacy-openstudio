# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.


module LegacyOpenStudio

  class CommandManager

    def initialize
      # This is an usual class; it is all methods, no data.
      # Should this just be a Mixin?  or module?

      # It is also a kind of graveyard for old commands that I'm not using right now but don't want to delete.
    end


    def new_input_file
      if (prompt_for_save)
        Plugin.model_manager.close_input_file
        Plugin.model_manager.detach_input_file
        Plugin.model_manager.new_input_file
      end
    end


    def open_input_file

      #Sketchup.active_model.start_operation("Open IDF")

      model = Sketchup.active_model

      #if (Plugin.model_manager.input_file_attached?)
        #button = UI.messagebox("An EnergyPlus input file is already attached to this SketchUp model.\n" +
        #  "Do you want to merge another input file with the current input file?\n" +
        #  "Click YES if you want to merge the input files.\n" +
        #  "Click NO if you want to replace the input files.", MB_YESNOCANCEL)

        #if (button == 6)  # Yes
        #  merge = true
        #elsif (button == 7)  # No
        #  merge = false
        #else  # Cancel
        #  return
        #end
      #end
      if (Plugin.model_manager.input_file_dir == ".")
      
      end

 
      if (path = UI.open_panel("Open EnergyPlus Input File", Plugin.model_manager.input_file_dir, "*.idf; *.imf"))  # have not figured out how to set File Types popup yet

        Plugin.write_pref("Last Input File Dir", File.dirname(path))  # Save the dir so we can start here next time

      #  model.start_operation("Open EnergyPlus Input File")
        # start_operation suspends all callbacks until 'commit' is called.
        # not sure this is the right place for this...probably better inside model_manager

        #if (merge)
        #  original_path = Plugin.model_manager.input_file.path
        #  success = Plugin.model_manager.open_input_file(path)
        #  Plugin.model_manager.input_file.path = original_path

        #else  # replace

        if (prompt_for_save)
          Plugin.model_manager.close_input_file
          Plugin.model_manager.detach_input_file
          success = Plugin.model_manager.open_input_file(path)
        end
        
      end

      #Sketchup.active_model.commit_operation

      # if errors
      # rescue
      #Sketchup.active_model.abort_operation

    end


    def merge_input_file
      if (path = UI.open_panel("Merge EnergyPlus Input File", Plugin.model_manager.input_file_dir, "*.idf; *.imf"))
        #model.start_operation("Merge EnergyPlus Input File")
        success = Plugin.model_manager.merge_input_file(path)
      end
    end


    def save_input_file
      path = Plugin.model_manager.input_file.path

      if (path.nil?)
        save_input_file_as
      elsif (not File.exist?(path))
        # pop error msg first?  the path was there. but now has disappeared
        save_input_file_as     
      else
        # check if writable?
        Plugin.model_manager.save_input_file(path)
      end
    end


    def save_input_file_as
      if (path = UI.save_panel("Save EnergyPlus Input File", Plugin.model_manager.input_file_dir, Plugin.model_manager.input_file_name))
        Plugin.model_manager.save_input_file(path)
      end
    end


    def revert_input_file
      path = Plugin.model_manager.input_file.path
      Plugin.model_manager.close_input_file
      Plugin.model_manager.detach_input_file
      Plugin.model_manager.open_input_file(path)
    end


    def close_input_file
      if (prompt_for_save)  # should save prompt occur before the 'erase all' prompt?  or after?
        if (Plugin.read_pref("Erase Entities"))
          erase = true
        else
          button = UI.messagebox("Closing the EnergyPlus input file detaches it from this SketchUp model.\n" +
            "Do you also want to erase all of the SketchUp entities that are associated with EnergyPlus objects?", MB_YESNOCANCEL)

          if (button == 6)  # YES
            erase = true
          elsif (button == 7)  # NO
            erase = false
          else  # CANCEL
            return
          end
        end

        Plugin.model_manager.close_input_file      
        Plugin.model_manager.detach_input_file(erase)
        Plugin.model_manager.new_input_file
      end
    end


    def prompt_for_save
      if (Plugin.model_manager.input_file.modified?)
        button = UI.messagebox("Save changes to the EnergyPlus input file " + Plugin.model_manager.input_file_name + "?", MB_YESNOCANCEL )

        if (button == 6)  # YES
          save_input_file
        elsif (button == 2)  # Cancel
          return(false)
        end
      end

      return(true)
    end


    def open_eefg
      web_dialog = UI::WebDialog.new("EnergyPlus Example File Generator", true, "EEFG", width = 600, height = 500, left = 100, top = 100, true)
      web_dialog.set_url("http://apps1.eere.energy.gov/buildings/energyplus/cfm/inputs/")
      web_dialog.show

      $eefg = web_dialog  # Need this to keep the dialog from getting garbage collected.
    end


  end

end
