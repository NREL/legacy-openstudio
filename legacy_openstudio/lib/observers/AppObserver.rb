# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.


module LegacyOpenStudio

  class AppObserver < Sketchup::AppObserver

    # onNewModel get called when the 'New' menu item is clicked, even though the user clicks cancel!  Very strange.
    # The active_model object reference is even changed as well, although none of the content of the model changes...
    # onOpenModel has the same behavior.
    # The work-around is to save and compare the 'guid' which does not change unless a truly new model is created or opened.

    def onNewModel(model)
      #puts "AppObserver.onNewModel"

      if (Plugin.model_manager.nil?)
        Plugin.new_model  # This is required for the Mac

      elsif (Sketchup.active_model.guid != Plugin.model_manager.guid)
        # Could probably store @guid here on the observer.

        #puts "=> new model"

        prompt_for_save
        Plugin.model_manager.destroy
        Plugin.new_model
      end
    end


    def onOpenModel(model)
      #puts "AppObserver.onOpenModel"

      if (Sketchup.active_model.guid != Plugin.model_manager.guid)
        #puts "=> new model"
        prompt_for_save
        Plugin.model_manager.destroy
        Plugin.new_model
      end
    end


    # Note:  Sketchup.active_model is already nil at this point
    def onQuit
      #UI.messagebox("AppObserver.onQuit")

      prompt_for_save
      Plugin.model_manager.destroy
    end


  private
  
    def prompt_for_save
      if (Plugin.model_manager.input_file.modified?)
        button = UI.messagebox("Save changes to the EnergyPlus input file " + Plugin.model_manager.input_file_name + "?", MB_YESNO)

        # NOTE:  There is no 'Cancel' button because the SketchUp model is already destroyed...
        if (button == 6)  # YES
          Plugin.command_manager.save_input_file
        end
      end
    end


  end

end
