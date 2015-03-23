# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/dialogs/Dialogs")


module LegacyOpenStudio

  class ThermostatDialog < PropertiesDialog

    def initialize(container, interface, hash)
      super
      w = Plugin.platform_select(600, 600)
      h = Plugin.platform_select(420, 440)
      @container = WindowContainer.new("HVACTemplate:Thermostat", w, h, 150, 150)
      @container.set_file(Plugin.dir + "/lib/dialogs/html/Thermostat.html")
        
      @hash['NEW_THERMOSTAT'] = true
      @hash['NEW_THERMOSTAT_NAME'] = ""
      @hash['EXISTING_THERMOSTAT_NAME'] = ""
      @hash['CONSTANT_HEATING'] = true
      @hash['HEATING_SCHEDULE'] = ""
      @hash['CONSTANT_COOLING'] = true
      @hash['COOLING_SCHEDULE'] = ""
      
      if (Plugin.model_manager.units_system == "SI")
        i = 0
        @hash['HEATING_SETPOINT'] = 20.0
        @hash['COOLING_SETPOINT'] = 25.0
      else
        i = 1
        @hash['HEATING_SETPOINT'] = 68.0
        @hash['COOLING_SETPOINT'] = 78.0
      end
      @hash['HEATING_SETPOINT_LABEL'] = "Constant Heating Setpoint " + Plugin.model_manager.units_hash['C'][i] + ":"
      @hash['COOLING_SETPOINT_LABEL'] = "Constant Cooling Setpoint " + Plugin.model_manager.units_hash['C'][i] + ":"
      
      on_update_options

      add_callbacks
    end
    
    def to_new
      @hash['NEW_THERMOSTAT'] = true
      on_update_options
    end
    
    def to_existing
      @hash['NEW_THERMOSTAT'] = false
      on_update_options
      on_update_existing
    end
    
    def add_callbacks
      super
      @container.web_dialog.add_action_callback("on_update_options") { on_update_options }
      @container.web_dialog.add_action_callback("on_update_existing") { on_update_existing }
      @container.web_dialog.add_action_callback("on_new_schedule") { on_new_schedule }
      @container.web_dialog.add_action_callback("on_cancel") { on_cancel }
      @container.web_dialog.add_action_callback("on_apply") { on_apply }
      @container.web_dialog.add_action_callback("on_ok") { on_ok }
    end
    
    def on_load
      super
      on_update_options
    end 
    
    def on_update_options
      
      schedule_names = Plugin.model_manager.input_file.find_objects_by_class_name("SCHEDULE:YEAR", "SCHEDULE:COMPACT", "SCHEDULE:FILE").collect { |object| object.name }
      schedule_names = schedule_names.sort
      
      set_select_options("HEATING_SCHEDULE", schedule_names)  
      set_select_options("COOLING_SCHEDULE", schedule_names)  

      thermostat_names = Plugin.model_manager.input_file.find_objects_by_class_name("HVACTEMPLATE:THERMOSTAT").collect { |object| object.name }
      thermostat_names = thermostat_names.sort
      
      set_select_options("EXISTING_THERMOSTAT_NAME", thermostat_names)  
      if @hash['NEW_THERMOSTAT'] 
        @hash['EXISTING_THERMOSTAT_NAME'] = "" 
        enable_element("NEW_THERMOSTAT_NAME")
        disable_element("EXISTING_THERMOSTAT_NAME")
      else
        @hash['NEW_THERMOSTAT_NAME'] = "" 
        if thermostat_names.empty?
          @hash['EXISTING_THERMOSTAT_NAME'] = ""
        elsif @hash['EXISTING_THERMOSTAT_NAME'].empty?
          @hash['EXISTING_THERMOSTAT_NAME'] = thermostat_names[0] 
        else
          # no-op
        end
        disable_element("NEW_THERMOSTAT_NAME")
        enable_element("EXISTING_THERMOSTAT_NAME")
      end
      
      if @hash['CONSTANT_HEATING'] 
        @hash['HEATING_SCHEDULE'] = "" 
        enable_element("HEATING_SETPOINT")
        disable_element("HEATING_SCHEDULE")
      else
        @hash['HEATING_SETPOINT'] = "" 
        disable_element("HEATING_SETPOINT")
        enable_element("HEATING_SCHEDULE")
      end
      
      if @hash['CONSTANT_COOLING'] 
        @hash['COOLING_SCHEDULE'] = "" 
        enable_element("COOLING_SETPOINT")
        disable_element("COOLING_SCHEDULE")
      else
        @hash['COOLING_SETPOINT'] = "" 
        disable_element("COOLING_SETPOINT")
        enable_element("COOLING_SCHEDULE")
      end
      
      update
      
    end
    
    def c_to_f(c)
      return( ((c*9.0/5.0)+32.0).round_to(Plugin.model_manager.length_precision) )
    end
    
    def f_to_c(f)
      return( ((f-32.0)*5.0/9.0).round_to(Plugin.model_manager.length_precision) )
    end
    
    def on_update_existing
    
      input_object = Plugin.model_manager.input_file.find_object_by_class_and_name("HVACTEMPLATE:THERMOSTAT", @hash["EXISTING_THERMOSTAT_NAME"])
      
      if input_object.nil?
        return 
      end
      
      heating_schedule = input_object.fields[2].to_s
      cooling_schedule = input_object.fields[4].to_s
      
      @hash['NEW_THERMOSTAT'] = false
      @hash['NEW_THERMOSTAT_NAME'] = ""
      @hash['EXISTING_THERMOSTAT_NAME'] = input_object.fields[1]
      @hash['CONSTANT_HEATING'] = heating_schedule.empty?
      @hash['HEATING_SCHEDULE'] = heating_schedule
      @hash['CONSTANT_COOLING'] = cooling_schedule.empty?
      @hash['COOLING_SCHEDULE'] = cooling_schedule
      
      if (Plugin.model_manager.units_system == "SI")
        i = 0
        if @hash['CONSTANT_HEATING']
          @hash['HEATING_SETPOINT'] = input_object.fields[3].to_f
        else
          @hash['HEATING_SETPOINT'] = ""
        end
        if @hash['CONSTANT_COOLING']
          @hash['COOLING_SETPOINT'] = input_object.fields[5].to_f
        else
          @hash['COOLING_SETPOINT'] = ""
        end
      else
        i = 1
        if @hash['CONSTANT_HEATING']
          @hash['HEATING_SETPOINT'] = c_to_f(input_object.fields[3].to_f)
        else
          @hash['HEATING_SETPOINT'] = ""
        end
        if @hash['CONSTANT_COOLING']
          @hash['COOLING_SETPOINT'] = c_to_f(input_object.fields[5].to_f)
        else
          @hash['COOLING_SETPOINT'] = ""
        end
      end
      @hash['HEATING_SETPOINT_LABEL'] = "Constant Heating Setpoint " + Plugin.model_manager.units_hash['C'][i] + ":"
      @hash['COOLING_SETPOINT_LABEL'] = "Constant Cooling Setpoint " + Plugin.model_manager.units_hash['C'][i] + ":"
      
      on_update_options
      
    end
    
    def on_new_schedule
      Plugin.model_manager.schedule_manager.new_schedule_stub
      on_update_options
    end
    
    def on_cancel
      close
    end
    
    def on_apply
      
      thermostats = Plugin.model_manager.input_file.find_objects_by_class_name("HVACTEMPLATE:THERMOSTAT")
      
      if @hash['NEW_THERMOSTAT'] 
        
        if (thermostats.find { |thermostat| thermostat.name == @hash['NEW_THERMOSTAT_NAME']  })
          UI.messagebox('The name "' +@hash['NEW_THERMOSTAT_NAME']  + '" is already in use by another HVACTemplate:Thermostat object.' + "\nNo object was created.")
        elsif (@hash['NEW_THERMOSTAT_NAME'].empty?)
          UI.messagebox('The name "" is not valid for a HVACTemplate:Thermostat object.' + "\nNo object was created.")
        else
          input_object = InputObject.new("HVACTemplate:Thermostat")
          input_object.fields[1] = @hash['NEW_THERMOSTAT_NAME']
          input_object.fields[2] = @hash['HEATING_SCHEDULE']
          input_object.fields[4] = @hash['COOLING_SCHEDULE']
          
          if (Plugin.model_manager.units_system == "SI")
            i = 0
            if @hash['CONSTANT_HEATING']
              input_object.fields[3] = @hash['HEATING_SETPOINT'].to_f
            else
              input_object.fields[3] = ""
            end
            if @hash['CONSTANT_COOLING']
              input_object.fields[5] = @hash['COOLING_SETPOINT'].to_f
            else
              input_object.fields[5] = ""
            end
          else
            i = 1
            if @hash['CONSTANT_HEATING']
              input_object.fields[3] = f_to_c(@hash['HEATING_SETPOINT'].to_f)
            else
              input_object.fields[3] = ""
            end
            if @hash['CONSTANT_COOLING']
              input_object.fields[5] = f_to_c(@hash['COOLING_SETPOINT'].to_f)
            else
              input_object.fields[5] = ""
            end
          end
          @hash['HEATING_SETPOINT_LABEL'] = "Constant Heating Setpoint " + Plugin.model_manager.units_hash['C'][i] + ":"
          @hash['COOLING_SETPOINT_LABEL'] = "Constant Cooling Setpoint " + Plugin.model_manager.units_hash['C'][i] + ":"
          
          Plugin.model_manager.input_file.add_object(input_object)
          Plugin.model_manager.input_file.modified = true
        end
       
      else
        
        if (input_object = thermostats.find { |thermostat| thermostat.name == @hash['EXISTING_THERMOSTAT_NAME']  })
          input_object.fields[2] = @hash['HEATING_SCHEDULE']
          input_object.fields[4] = @hash['COOLING_SCHEDULE']    
          
          if (Plugin.model_manager.units_system == "SI")
            i = 0
            if @hash['CONSTANT_HEATING']
              input_object.fields[3] = @hash['HEATING_SETPOINT'].to_f
            else
              input_object.fields[3] = ""
            end
            if @hash['CONSTANT_COOLING']
              input_object.fields[5] = @hash['COOLING_SETPOINT'].to_f
            else
              input_object.fields[5] = ""
            end
          else
            i = 1
            if @hash['CONSTANT_HEATING']
              input_object.fields[3] = f_to_c(@hash['HEATING_SETPOINT'].to_f)
            else
              input_object.fields[3] = ""
            end
            if @hash['CONSTANT_COOLING']
              input_object.fields[5] = f_to_c(@hash['COOLING_SETPOINT'].to_f)
            else
              input_object.fields[5] = ""
            end
          end
          @hash['HEATING_SETPOINT_LABEL'] = "Constant Heating Setpoint " + Plugin.model_manager.units_hash['C'][i] + ":"
          @hash['COOLING_SETPOINT_LABEL'] = "Constant Cooling Setpoint " + Plugin.model_manager.units_hash['C'][i] + ":"
          
          Plugin.model_manager.input_file.modified = true
        else
          UI.messagebox('Could not find HVACTemplate:Thermostat object ' + @hash['EXISTING_THERMOSTAT_NAME'] + '.' )
        end

      end

    end
    
    def on_ok
      on_apply
      close
    end

  end

end
