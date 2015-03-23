# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.


module LegacyOpenStudio

  # This is a kludge to get a selection update when a Group is closed after being edited.
  # SelectionObserver does not provide any event.  Fortunately, InstanceObserver, which
  # also happens to work for Groups, DOES give an event that can be used.
  class InstanceObserver < Sketchup::InstanceObserver
  
    def initialize(drawing_interface=nil)
      # for drawing interfaces that want update_entity on close
      @drawing_interface = drawing_interface
    end
    
    def onOpen(group)
    end

    def onClose(group)
      Plugin.model_manager.selection_changed
    end

  end


end
