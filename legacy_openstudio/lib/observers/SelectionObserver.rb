# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.


module LegacyOpenStudio

  class SelectionObserver < Sketchup::SelectionObserver
    
    def onSelectionAdded(*args)
      # Called when a new entity is added and selected.
      #puts "SelectionObserver.onSelectionAdded"
      Plugin.model_manager.selection_changed
    end


    def onSelectionBulkChange(selection)
      # Called for almost every change in selection, except when going to no selection (onSelectionCleared gets called instead).
      #puts "SelectionObserver.onSelectionBulkChange"
      Plugin.model_manager.selection_changed
    end


    def onSelectionCleared(selection)
      # Called when going from a selection to an empty selection.
      #puts "SelectionObserver.onSelectionCleared"
      Plugin.model_manager.selection_changed
    end


    def onSelectionRemoved(selection)
      # Not sure when this is called.    
      #puts "SelectionObserver.onSelectionRemoved"
    end

  end

end
