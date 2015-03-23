# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/AsynchProc")
require("legacy_openstudio/lib/Collection")


module LegacyOpenStudio

  class DialogManager

    attr_accessor :dialog_interfaces


    def initialize
      @dialog_interfaces = Collection.new
      restore_state
    end


    def save_state
      interface_names = @dialog_interfaces.collect { |interface| interface.class.to_s[12..-1] }  # Clip the "LegacyOpenStudio::" part
      Plugin.write_pref('Open Dialogs', interface_names.to_a.join(','))
    end


    def restore_state
      interface_names = Plugin.read_pref('Open Dialogs').split(',')
      interface_names.each { |interface_name| AsynchProc.new { show(LegacyOpenStudio.const_get(interface_name)) } }
    end


    def active_interface(interface_class)
      return(@dialog_interfaces.find { |interface| interface.class == interface_class })
    end


    def show(interface_class)
      if (not interface = active_interface(interface_class))
        interface = interface_class.new
        @dialog_interfaces.add(interface)
      end
      interface.show
      save_state
    end


    def validate(interface_class)
      state = MF_UNCHECKED
      if (Plugin.model_manager)
        if (active_interface(interface_class))
          state = MF_CHECKED
        end
      end
      return(state)
    end


    def update(interface_class)
      if (interface = active_interface(interface_class))
        interface.update
      end
    end


    def update_all
      @dialog_interfaces.each { |interface| interface.update }
    end


    def update_units
      @dialog_interfaces.each { |interface| interface.update_units }
    end


    def remove(interface)
      @dialog_interfaces.remove(interface)
      save_state
    end


    def close_all
      @dialog_interfaces.each { |interface| AsynchProc.new { interface.close } }
    end

  end

end
