# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.


module LegacyOpenStudio

  class ModelObserver < Sketchup::ModelObserver

    def onSaveModel(model)
      puts "Model.onSaveModel"

      Plugin.model_manager.model_interface.on_save_model  # More of the stuff below can move into this method later

      input_file_attached = Plugin.model_manager.input_file_attached?

      Plugin.command_manager.save_input_file

      if (not input_file_attached and Plugin.model_manager.input_file_attached?)
        # The 'save_input_file' method just saved the IDF for the first time.
        # That means the SKP file needs to be updated with a persistent link to the IDF path
        # or else the IDF won't be reopened when the SKP file is reopened.
        # Solution is to force the SKP file to save again now that it's been updated with the IDF path.
        if (not @saved_again)
          Sketchup.send_action("saveDocument:")
          puts "Resaving the document"
          @saved_again = true  # Flag to prevent infinite looping
        else
          @saved_again = false
        end
      end
    end
    
    # onDeleteModel
    
    # onEraseAll
    
    #def onTransactionStart(model)
      #puts "onTransactionStart"
    #end
   
    #def onTransactionEnd(model)
      #puts "onTransactionEnd"
    #end

    #def onTransactionUndo(model)
      #puts "onTransactionUndo"
    #end
    
    # onTransactionRedo

    #def onTransactionCommit(model)
      #puts "onTransactionCommit"
    #end
    
    # onTransactionAbort
    
    # onTransactionEmpty

  end

end
