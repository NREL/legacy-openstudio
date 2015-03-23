# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/dialogs/Dialogs")
require("legacy_openstudio/lib/dialogs/ThermostatInterface")
require("legacy_openstudio/lib/dialogs/LastReportInterface")

module LegacyOpenStudio

  class ZoneLoadsDialog < PropertiesDialog

    def initialize(container, interface, hash)
      super
      w = Plugin.platform_select(600, 600)
      h = Plugin.platform_select(800, 840)
      @container = WindowContainer.new("Zone Loads", w, h, 150, 150)
      @container.set_file(Plugin.dir + "/lib/dialogs/html/ZoneLoads.html")
      
      # value_hash is actual values in metric units, this is what gets saved and written to idf
      @value_hash = Hash.new
      @value_hash['PEOPLE_DENSITY'] = 0.0
      @value_hash['OCCUPANCY_SCHEDULE'] = ""
      @value_hash['ACTIVITY_SCHEDULE'] = ""
      @value_hash['LIGHTS_DENSITY'] = 0.0
      @value_hash['LIGHTS_SCHEDULE'] = ""
      @value_hash['ELEC_EQUIPMENT_DENSITY'] = 0.0
      @value_hash['ELEC_EQUIPMENT_SCHEDULE'] = ""
      @value_hash['GAS_EQUIPMENT_DENSITY'] = 0.0
      @value_hash['GAS_EQUIPMENT_SCHEDULE'] = ""
      @value_hash['OA_PER_PERSON'] = 0.0
      @value_hash['OA_PER_PERSON_SCHEDULE'] = ""
      @value_hash['OA_PER_AREA'] = 0.0
      @value_hash['OA_PER_AREA_SCHEDULE'] = ""
      @value_hash['INFILTRATION_RATE'] = 0.0
      @value_hash['INFILTRATION_SCHEDULE'] = ""
      @value_hash['ADD_IDEAL_LOADS'] = true
      @value_hash['THERMOSTAT_NAME'] = ""
      
      # hash is what is presented
      @hash['DEFAULT_SAVE_PATH'] = ""
      @hash['PEOPLE_DENSITY_TEXT'] = ""
      @hash['PEOPLE_DENSITY'] = ""
      @hash['OCCUPANCY_SCHEDULE'] = ""
      @hash['ACTIVITY_SCHEDULE'] = ""
      @hash['LIGHTS_DENSITY_TEXT'] = ""
      @hash['LIGHTS_DENSITY'] = ""
      @hash['LIGHTS_SCHEDULE'] = ""
      @hash['ELEC_EQUIPMENT_DENSITY_TEXT'] = ""
      @hash['ELEC_EQUIPMENT_DENSITY'] = ""
      @hash['ELEC_EQUIPMENT_SCHEDULE'] = ""
      @hash['GAS_EQUIPMENT_DENSITY_TEXT'] = ""
      @hash['GAS_EQUIPMENT_DENSITY'] = ""
      @hash['GAS_EQUIPMENT_SCHEDULE'] = ""
      @hash['OA_PER_PERSON_TEXT'] = ""
      @hash['OA_PER_PERSON'] = ""
      @hash['OA_PER_PERSON_SCHEDULE'] = ""
      @hash['OA_PER_AREA_TEXT'] = ""
      @hash['OA_PER_AREA'] = ""
      @hash['OA_PER_AREA_SCHEDULE'] = ""
      @hash['INFILTRATION_RATE'] = ""
      @hash['INFILTRATION_SCHEDULE'] = ""
      @hash['ADD_IDEAL_LOADS'] = true
      @hash['THERMOSTAT_NAME'] = ""
      
      @last_report = ""
      
      add_callbacks
    end
    
    def reset_values
      @value_hash['PEOPLE_DENSITY'] = 0.05382 # 5 people/1000ft2
      @value_hash['OCCUPANCY_SCHEDULE'] = "Office Occupancy Schedule"
      @value_hash['ACTIVITY_SCHEDULE'] = "Office Activity Schedule"
      @value_hash['LIGHTS_DENSITY'] = 10.7639104 # 1.0 W/ft2
      @value_hash['LIGHTS_SCHEDULE'] = "Office Lights Schedule"
      @value_hash['ELEC_EQUIPMENT_DENSITY'] = 10.7639104 # 1.0 W/ft2
      @value_hash['ELEC_EQUIPMENT_SCHEDULE'] = "Office Equipment Schedule"
      @value_hash['GAS_EQUIPMENT_DENSITY'] = 0.0000 
      @value_hash['GAS_EQUIPMENT_SCHEDULE'] = "Office Equipment Schedule"
      @value_hash['OA_PER_PERSON'] = 0.00236 # 5 cfm/person
      @value_hash['OA_PER_PERSON_SCHEDULE'] = @value_hash['OCCUPANCY_SCHEDULE']
      @value_hash['OA_PER_AREA'] = 0.000305 # 0.06 cfm/ft2
      @value_hash['OA_PER_AREA_SCHEDULE'] = "Always On"
      @value_hash['INFILTRATION_RATE'] = 0.5
      @value_hash['INFILTRATION_SCHEDULE'] = "Infiltration Half On Schedule"
      @value_hash['THERMOSTAT_NAME'] = "Constant Setpoint Thermostat"
   end

    # translate from value hash to hash
    def update_hash

      if (Plugin.model_manager.units_system == "SI")
        i = 0
        m3s_to_ls = 1000.0
        @hash['PEOPLE_DENSITY_TEXT'] = "  People per Zone Floor Area " + Plugin.model_manager.units_hash['People/100m2'][i] + ":"
        @hash['PEOPLE_DENSITY'] = (100.0*@value_hash['PEOPLE_DENSITY']).round_to(6).to_s
        @hash['OCCUPANCY_SCHEDULE'] = @value_hash['OCCUPANCY_SCHEDULE']
        @hash['ACTIVITY_SCHEDULE'] = @value_hash['ACTIVITY_SCHEDULE']
        @hash['LIGHTS_DENSITY_TEXT'] = "  Lighting Power Density " + Plugin.model_manager.units_hash['W/m2'][i] + ":"
        @hash['LIGHTS_DENSITY'] = @value_hash['LIGHTS_DENSITY'].round_to(4).to_s
        @hash['LIGHTS_SCHEDULE'] = @value_hash['LIGHTS_SCHEDULE']
        @hash['ELEC_EQUIPMENT_DENSITY_TEXT'] = "  Electric Equipment Power Density " + Plugin.model_manager.units_hash['W/m2'][i] + ":"
        @hash['ELEC_EQUIPMENT_DENSITY'] = @value_hash['ELEC_EQUIPMENT_DENSITY'].round_to(4).to_s
        @hash['ELEC_EQUIPMENT_SCHEDULE'] = @value_hash['ELEC_EQUIPMENT_SCHEDULE']
        @hash['GAS_EQUIPMENT_DENSITY_TEXT'] = "  Gas Equipment Power Density " + Plugin.model_manager.units_hash['W/m2'][i] + ":"
        @hash['GAS_EQUIPMENT_DENSITY'] = @value_hash['GAS_EQUIPMENT_DENSITY'].round_to(4).to_s
        @hash['GAS_EQUIPMENT_SCHEDULE'] = @value_hash['GAS_EQUIPMENT_SCHEDULE']
        @hash['OA_PER_PERSON_TEXT'] = "  Outdoor Air per Person " + Plugin.model_manager.units_hash['L/sec/person'][i] + ":"
        @hash['OA_PER_PERSON'] = (m3s_to_ls*@value_hash['OA_PER_PERSON']).round_to(6).to_s
        @hash['OA_PER_PERSON_SCHEDULE'] = @value_hash['OA_PER_PERSON_SCHEDULE']
        @hash['OA_PER_AREA_TEXT'] = "  Outdoor Air per Area " + Plugin.model_manager.units_hash['L/sec/m2'][i] + ":"
        @hash['OA_PER_AREA'] = (m3s_to_ls*@value_hash['OA_PER_AREA']).round_to(6).to_s
        @hash['OA_PER_AREA_SCHEDULE'] = @value_hash['OA_PER_AREA_SCHEDULE']
        @hash['INFILTRATION_RATE'] = @value_hash['INFILTRATION_RATE'].round_to(4).to_s
        @hash['INFILTRATION_SCHEDULE'] = @value_hash['INFILTRATION_SCHEDULE']
        @hash['ADD_IDEAL_LOADS'] = @value_hash['ADD_IDEAL_LOADS']    
        @hash['THERMOSTAT_NAME'] = @value_hash['THERMOSTAT_NAME']          
      else
        i = 1
        m2_over_ft2 = 0.092903
        ft2_over_m2 = 1/m2_over_ft2
        m3s_to_cfm = 2118.8799728
        @hash['PEOPLE_DENSITY_TEXT'] = "  People per Zone Floor Area " + Plugin.model_manager.units_hash['People/100m2'][i] + ":"
        @hash['PEOPLE_DENSITY'] = (1000.0*m2_over_ft2*@value_hash['PEOPLE_DENSITY']).round_to(6).to_s
        @hash['OCCUPANCY_SCHEDULE'] = @value_hash['OCCUPANCY_SCHEDULE']
        @hash['ACTIVITY_SCHEDULE'] = @value_hash['ACTIVITY_SCHEDULE']
        @hash['LIGHTS_DENSITY_TEXT'] = "  Lighting Power Density " + Plugin.model_manager.units_hash['W/m2'][i] + ":"
        @hash['LIGHTS_DENSITY'] = (m2_over_ft2*@value_hash['LIGHTS_DENSITY']).round_to(4).to_s
        @hash['LIGHTS_SCHEDULE'] = @value_hash['LIGHTS_SCHEDULE']
        @hash['ELEC_EQUIPMENT_DENSITY_TEXT'] = "  Electric Equipment Power Density " + Plugin.model_manager.units_hash['W/m2'][i] + ":"
        @hash['ELEC_EQUIPMENT_DENSITY'] = (m2_over_ft2*@value_hash['ELEC_EQUIPMENT_DENSITY']).round_to(4).to_s
        @hash['ELEC_EQUIPMENT_SCHEDULE'] = @value_hash['ELEC_EQUIPMENT_SCHEDULE']
        @hash['GAS_EQUIPMENT_DENSITY_TEXT'] = "  Gas Equipment Power Density " + Plugin.model_manager.units_hash['W/m2'][i] + ":"
        @hash['GAS_EQUIPMENT_DENSITY'] = (m2_over_ft2*@value_hash['GAS_EQUIPMENT_DENSITY']).round_to(4).to_s
        @hash['GAS_EQUIPMENT_SCHEDULE'] = @value_hash['GAS_EQUIPMENT_SCHEDULE']
        @hash['OA_PER_PERSON_TEXT'] = "  Outdoor Air per Person " + Plugin.model_manager.units_hash['L/sec/person'][i] + ":"
        @hash['OA_PER_PERSON'] = (m3s_to_cfm*@value_hash['OA_PER_PERSON']).round_to(6).to_s
        @hash['OA_PER_PERSON_SCHEDULE'] = @value_hash['OA_PER_PERSON_SCHEDULE']
        @hash['OA_PER_AREA_TEXT'] = "  Outdoor Air per Area " + Plugin.model_manager.units_hash['L/sec/m2'][i] + ":"
        @hash['OA_PER_AREA'] = (m3s_to_cfm*m2_over_ft2*@value_hash['OA_PER_AREA']).round_to(6).to_s
        @hash['OA_PER_AREA_SCHEDULE'] = @value_hash['OA_PER_AREA_SCHEDULE']  
        @hash['INFILTRATION_RATE'] = @value_hash['INFILTRATION_RATE'].round_to(4).to_s
        @hash['INFILTRATION_SCHEDULE'] = @value_hash['INFILTRATION_SCHEDULE']
        @hash['ADD_IDEAL_LOADS'] = @value_hash['ADD_IDEAL_LOADS'] 
        @hash['THERMOSTAT_NAME'] = @value_hash['THERMOSTAT_NAME']       
      end
    end
    
    # translate from hash to value hash
    def update_value_hash

      if (Plugin.model_manager.units_system == "SI")
        i = 0
        m3s_to_ls = 1000.0
        ls_to_m3s = 1/m3s_to_ls
        @value_hash['PEOPLE_DENSITY'] = @hash['PEOPLE_DENSITY'].to_f/100.0
        @value_hash['OCCUPANCY_SCHEDULE'] = @hash['OCCUPANCY_SCHEDULE']
        @value_hash['ACTIVITY_SCHEDULE'] = @hash['ACTIVITY_SCHEDULE']
        @value_hash['LIGHTS_DENSITY'] = @hash['LIGHTS_DENSITY'].to_f
        @value_hash['LIGHTS_SCHEDULE'] = @hash['LIGHTS_SCHEDULE']
        @value_hash['ELEC_EQUIPMENT_DENSITY'] = @hash['ELEC_EQUIPMENT_DENSITY'].to_f
        @value_hash['ELEC_EQUIPMENT_SCHEDULE'] = @hash['ELEC_EQUIPMENT_SCHEDULE']
        @value_hash['GAS_EQUIPMENT_DENSITY'] = @hash['GAS_EQUIPMENT_DENSITY'].to_f
        @value_hash['GAS_EQUIPMENT_SCHEDULE'] = @hash['GAS_EQUIPMENT_SCHEDULE']
        @value_hash['OA_PER_AREA_TEXT'] = @hash['OA_PER_AREA_TEXT']
        @value_hash['OA_PER_PERSON'] = ls_to_m3s*@hash['OA_PER_PERSON'].to_f
        @value_hash['OA_PER_PERSON_SCHEDULE'] = @hash['OA_PER_PERSON_SCHEDULE']
        @value_hash['OA_PER_AREA_TEXT'] = @hash['OA_PER_AREA_TEXT']
        @value_hash['OA_PER_AREA'] = ls_to_m3s*@hash['OA_PER_AREA'].to_f
        @value_hash['OA_PER_AREA_SCHEDULE'] = @hash['OA_PER_AREA_SCHEDULE']    
        @value_hash['INFILTRATION_RATE'] = @hash['INFILTRATION_RATE'].to_f
        @value_hash['INFILTRATION_SCHEDULE'] = @hash['INFILTRATION_SCHEDULE']
        @value_hash['ADD_IDEAL_LOADS'] = @hash['ADD_IDEAL_LOADS']   
        @value_hash['THERMOSTAT_NAME'] = @hash['THERMOSTAT_NAME']          
      else
        i = 1
        m2_over_ft2 = 0.092903
        ft2_over_m2 = 1/m2_over_ft2
        m3s_to_cfm = 2118.8799728
        cfm_to_m3s = 1/m3s_to_cfm
        @value_hash['PEOPLE_DENSITY'] = ft2_over_m2*@hash['PEOPLE_DENSITY'].to_f/1000.0
        @value_hash['OCCUPANCY_SCHEDULE'] = @hash['OCCUPANCY_SCHEDULE']
        @value_hash['ACTIVITY_SCHEDULE'] = @hash['ACTIVITY_SCHEDULE']
        @value_hash['LIGHTS_DENSITY'] = ft2_over_m2*@hash['LIGHTS_DENSITY'].to_f
        @value_hash['LIGHTS_SCHEDULE'] = @hash['LIGHTS_SCHEDULE']
        @value_hash['ELEC_EQUIPMENT_DENSITY'] = ft2_over_m2*@hash['ELEC_EQUIPMENT_DENSITY'].to_f
        @value_hash['ELEC_EQUIPMENT_SCHEDULE'] = @hash['ELEC_EQUIPMENT_SCHEDULE']
        @value_hash['GAS_EQUIPMENT_DENSITY'] = ft2_over_m2*@hash['GAS_EQUIPMENT_DENSITY'].to_f
        @value_hash['GAS_EQUIPMENT_SCHEDULE'] = @hash['GAS_EQUIPMENT_SCHEDULE']
        @value_hash['OA_PER_AREA_TEXT'] = @hash['OA_PER_AREA_TEXT']
        @value_hash['OA_PER_PERSON'] = cfm_to_m3s*@hash['OA_PER_PERSON'].to_f
        @value_hash['OA_PER_PERSON_SCHEDULE'] = @hash['OA_PER_PERSON_SCHEDULE']
        @value_hash['OA_PER_AREA_TEXT'] = @hash['OA_PER_AREA_TEXT']
        @value_hash['OA_PER_AREA'] = cfm_to_m3s*ft2_over_m2*@hash['OA_PER_AREA'].to_f
        @value_hash['OA_PER_AREA_SCHEDULE'] = @hash['OA_PER_AREA_SCHEDULE']      
        @value_hash['INFILTRATION_RATE'] = @hash['INFILTRATION_RATE'].to_f
        @value_hash['INFILTRATION_SCHEDULE'] = @hash['INFILTRATION_SCHEDULE']
        @value_hash['ADD_IDEAL_LOADS'] = @hash['ADD_IDEAL_LOADS']  
        @value_hash['THERMOSTAT_NAME'] = @hash['THERMOSTAT_NAME']      
      end
    end

    def add_callbacks
      super
      @container.web_dialog.add_action_callback("on_update") { update }
      @container.web_dialog.add_action_callback("on_report_update") { on_report_update }
      @container.web_dialog.add_action_callback("on_open") { on_open }
      @container.web_dialog.add_action_callback("on_new_schedule") { on_new_schedule }
      @container.web_dialog.add_action_callback("on_add_thermostats") { on_add_thermostats }
      @container.web_dialog.add_action_callback("on_edit_thermostats") { on_edit_thermostats }
      @container.web_dialog.add_action_callback("on_refresh_thermostats") { on_refresh_thermostats }
      @container.web_dialog.add_action_callback("on_reset") { on_reset }
      @container.web_dialog.add_action_callback("on_ok") { on_ok }
      @container.web_dialog.add_action_callback("on_save") { on_save }
      @container.web_dialog.add_action_callback("on_save_as") { on_save_as }
      @container.web_dialog.add_action_callback("on_cancel") { on_cancel }
      @container.web_dialog.add_action_callback("on_set_selected") { on_set_selected }
      @container.web_dialog.add_action_callback("on_set_all") { on_set_all }
      @container.web_dialog.add_action_callback("on_last_report") { on_last_report }
    end
    
    def on_load
      super
      update
    end 
    
    # update the html page from the hash
    def update
    
      @value_hash = Plugin.model_manager.zone_loads_manager if not Plugin.model_manager.zone_loads_manager.nil?
    
      update_hash
      
      schedule_names = Plugin.model_manager.input_file.find_objects_by_class_name("SCHEDULE:YEAR", "SCHEDULE:COMPACT", "SCHEDULE:FILE").collect { |object| object.name }
      schedule_names = schedule_names.sort

      set_select_options("OCCUPANCY_SCHEDULE", schedule_names)  
      set_select_options("ACTIVITY_SCHEDULE", schedule_names)  
      set_select_options("LIGHTS_SCHEDULE", schedule_names)  
      set_select_options("ELEC_EQUIPMENT_SCHEDULE", schedule_names)  
      set_select_options("GAS_EQUIPMENT_SCHEDULE", schedule_names)  
      set_select_options("OA_PER_PERSON_SCHEDULE", schedule_names) 
      set_select_options("OA_PER_AREA_SCHEDULE", schedule_names) 
      set_select_options("INFILTRATION_SCHEDULE", schedule_names)  
      
      if @hash['ADD_IDEAL_LOADS']
        thermostat_names = Plugin.model_manager.input_file.find_objects_by_class_name("HVACTEMPLATE:THERMOSTAT").collect { |object| object.name }
        thermostat_names = thermostat_names.sort

        enable_element("THERMOSTAT_NAME")
        enable_element("ADD_THERMOSTATS")
        enable_element("EDIT_THERMOSTATS")
        enable_element("REFRESH_THERMOSTATS")
        set_select_options("THERMOSTAT_NAME", thermostat_names)  
      else
        disable_element("THERMOSTAT_NAME")
        disable_element("ADD_THERMOSTATS")
        disable_element("EDIT_THERMOSTATS")
        disable_element("REFRESH_THERMOSTATS")
        set_select_options("THERMOSTAT_NAME", thermostat_names)
      end
      
      super
    end
    
    # update the hash from html page
    def report
      update_value_hash
      Plugin.model_manager.zone_loads_manager = @value_hash
      super
    end    
    
    def on_report_update
      report
      update
    end
    
    def on_open
      if (@hash['DEFAULT_SAVE_PATH'].empty?)
        dir = Plugin.model_manager.input_file_dir
        file_name = "*.zone_loads"      
      else
        dir = File.dirname(@hash['DEFAULT_SAVE_PATH'])
        file_name = File.basename(@hash['DEFAULT_SAVE_PATH'])
      end

      if (file_path = UI.open_panel("Locate Zone Loads Preferences", dir, file_name))
        file_path = file_path.split("\\").join("/")
      
        if (File.exists?(file_path))
          begin
        
            File.open(file_path, 'r') do |file|
              @value_hash = Marshal.load(file)
            end
            update_hash
            @hash['DEFAULT_SAVE_PATH'] = file_path
            report
            update

          rescue Exception => e
            UI.messagebox(file_path.to_s, MB_OK)
            UI.messagebox(e.to_s, MB_OK)
            UI.messagebox("Invalid zone loads preferences file", MB_OK)
          end

        else
          UI.messagebox("Zone loads preferences file does not exist", MB_OK)
        end
      end      
    end
    
    def on_new_schedule
      report
      Plugin.model_manager.schedule_manager.new_schedule_stub
      update
    end
    
    def on_add_thermostats
      report
      Plugin.dialog_manager.show(ThermostatInterface)
      Plugin.dialog_manager.active_interface(ThermostatInterface).to_new
      update
    end
    
    def on_edit_thermostats
      report
      Plugin.dialog_manager.show(ThermostatInterface)
      Plugin.dialog_manager.active_interface(ThermostatInterface).to_existing
      update
    end
    
    def on_refresh_thermostats
      report
      update
    end
    
    def on_reset
      reset_values
      update
    end
    
    def on_ok
      report
      update
      close
    end
    
    def on_save
      report
      update
      
      if (@hash['DEFAULT_SAVE_PATH'].empty?)
        on_save_as
        return
      end
      
      if (File.exists?(@hash['DEFAULT_SAVE_PATH']))
        result = UI.messagebox("File exists, are you sure you want to overwrite?", MB_YESNO)
        if result == 7 # No
          return
        end
      end

      begin
        File.open(@hash['DEFAULT_SAVE_PATH'], 'w') do |file|
          Marshal.dump(@value_hash, file)
        end
      rescue Exception => e
        UI.messagebox("Save failed", MB_OK)
      end
    end
    
    def on_save_as
      report
      if (@hash['DEFAULT_SAVE_PATH'].empty?)
        dir = Plugin.model_manager.input_file_dir
        file_name = Plugin.model_manager.input_file_name + ".zone_loads"      
      else
        dir = File.dirname(@hash['DEFAULT_SAVE_PATH'])
        file_name = File.basename(@hash['DEFAULT_SAVE_PATH'])
      end

      if (file_path = UI.save_panel("Locate Zone Loads Preferences", dir, file_name))    
        @hash['DEFAULT_SAVE_PATH'] = file_path
        update
        on_save
      end
    end
    
    def on_cancel
      close
    end
    
    def get_schedule(name)
      Plugin.model_manager.input_file.find_objects_by_class_name("SCHEDULE:YEAR", "SCHEDULE:COMPACT", "SCHEDULE:FILE").each { |object| return object if object.name.upcase == name.upcase}
      return ""
    end
    
    def get_thermostat(name)
      Plugin.model_manager.input_file.find_objects_by_class_name("HVACTEMPLATE:THERMOSTAT").each { |object| return object if object.name.upcase == name.upcase}
      return ""
    end
    
    def remove_objects_in_zone(class_name, zone_name_index, zone_name)
      Plugin.model_manager.input_file.find_objects_by_class_name(class_name).each do |object| 
        if object.fields[zone_name_index].to_s.upcase == zone_name.upcase
          @last_report << "Removing #{object.class_name} '#{object.fields[1]}' from Zone '#{zone_name}'\n"
          Plugin.model_manager.input_file.delete_object(object) 
        end
      end
    end
    
    def add_object_to_zone(object, zone_name)
      @last_report << "Adding #{object.class_name} '#{object.fields[1]}' to Zone '#{zone_name}'\n"
      Plugin.model_manager.input_file.add_object(object)
    end
    
    def on_set_selected
      report
      model = Sketchup.active_model
      set_loads(model.selection)
    end
    
    def on_set_all
      report
      model = Sketchup.active_model
      model.selection.clear
      model.entities.each {|e| model.selection.add(e)}
      set_loads(model.selection) 
      model.selection.clear
    end
    
    def set_loads(selection)
    
      if selection.empty?
        UI.messagebox("Please select zones that you wish to add loads to before applying.")
        return false
      end
      
      result = nil
      if @hash['ADD_IDEAL_LOADS']
        result = UI.messagebox(
"Warning this will remove all objects of type
'People', 'Lights', 'ElectricEquipment', 'GasEquipment',
'ZoneVentilation:DesignFlowRate', 'ZoneInfiltration:DesignFlowRate', and 
'HVACTemplate:Zone:IdealLoadsAirSystem' within the selection.\n  
This operation cannot be undone.\n  
Do you want to continue?", MB_OKCANCEL)
    else
        result = UI.messagebox(
"Warning this will remove all objects of type
'People', 'Lights', 'ElectricEquipment', 'GasEquipment',
'ZoneVentilation:DesignFlowRate', and 'ZoneInfiltration:DesignFlowRate' within the selection.\n  
This operation cannot be undone.\n  
Do you want to continue?", MB_OKCANCEL)
    end

      @last_report = "Zone Loads Report:\n"

      if result == 2 # cancel
        return false
      end
      
      Plugin.model_manager.zones.each do |zone|
        # selection must contain zone
        next if not (selection.contains?(zone.entity))
        
        zone_name = zone.input_object.name
        
        # remove existing People, Lights, ElectricEquipment, GasEquipment, and ZoneInfiltration:DesignFlowRate, HVACTemplate:Zone:IdealLoadsAirSystem
        remove_objects_in_zone("People", 2, zone_name)
        remove_objects_in_zone("Lights", 2, zone_name)
        remove_objects_in_zone("ElectricEquipment", 2, zone_name)
        remove_objects_in_zone("GasEquipment", 2, zone_name)
        remove_objects_in_zone("ZoneVentilation:DesignFlowRate", 2, zone_name)
        remove_objects_in_zone("ZoneInfiltration:DesignFlowRate", 2, zone_name)
        
        if @hash['ADD_IDEAL_LOADS']
          remove_objects_in_zone("HVACTemplate:Zone:IdealLoadsAirSystem", 1, zone_name)
          #remove_objects_in_zone("HVACTemplate:Zone:FanCoil", 1, zone_name)
          #remove_objects_in_zone("HVACTemplate:Zone:PTAC", 1, zone_name)
          #remove_objects_in_zone("HVACTemplate:Zone:PTHP", 1, zone_name)
          #remove_objects_in_zone("HVACTemplate:Zone:Unitary", 1, zone_name)
          #remove_objects_in_zone("HVACTemplate:Zone:VAV", 1, zone_name)
          #remove_objects_in_zone("HVACTemplate:Zone:VAV:FanPowered", 1, zone_name)
        end
        
        # People
        if @value_hash['PEOPLE_DENSITY'] > 0
          input_object = InputObject.new("People")
          input_object.fields[1] = "#{zone_name} People" # Name
          input_object.fields[2] = zone_name  # Zone Name
          input_object.fields[3] = get_schedule(@hash['OCCUPANCY_SCHEDULE'] ) # Schedule Name
          input_object.fields[4] = "People/Area"  # Number of People Calculation Method
          input_object.fields[5] = "" # Number of People
          input_object.fields[6] = @value_hash['PEOPLE_DENSITY'].round_to(6).to_s # People per Zone Floor Area
          input_object.fields[7] =  ""  # Zone Floor Area per Person
          input_object.fields[8] = "0.3"  # Fraction Radiant
          input_object.fields[9] = ""  # Sensible Heat Fraction
          input_object.fields[10] = get_schedule(@hash['ACTIVITY_SCHEDULE'] )  # Activity Level Schedule Name
          input_object.fields[11] = ""  # Carbon Dioxide Generation Rate
          input_object.fields[12] = ""  # Enable ASHRAE 55 Comfort Warnings
          input_object.fields[13] = ""  # Mean Radiant Temperature Calculation Type
          input_object.fields[14] = ""  # Surface Name/Angle Factor List Name
          input_object.fields[15] = ""  # Work Efficiency Schedule Name
          input_object.fields[16] = ""  # Clothing Insulation Schedule Name
          input_object.fields[17] = ""  # Air Velocity Schedule Name
          input_object.fields[18] = ""  # Thermal Comfort Model 1 Type
          input_object.fields[19] = ""  # Thermal Comfort Model 2 Type
          input_object.fields[20] = ""  # Thermal Comfort Model 3 Type
          add_object_to_zone(input_object, zone_name)
        end
        
        # Lights
        if @value_hash['LIGHTS_DENSITY'] > 0
          input_object = InputObject.new("Lights")
          input_object.fields[1] = "#{zone_name} Lights" # Name
          input_object.fields[2] = zone_name  # Zone Name
          input_object.fields[3] = get_schedule(@hash['LIGHTS_SCHEDULE'] ) # Schedule Name
          input_object.fields[4] = "Watts/Area"  # Design Level Calculation Method
          input_object.fields[5] = ""  # Lighting Level
          input_object.fields[6] = @value_hash['LIGHTS_DENSITY'].round_to(4).to_s  # Watts per Zone Floor Area
          input_object.fields[7] = ""  # Watts per Person
          input_object.fields[8] = ""  # Return Air Fraction
          input_object.fields[9] = ""  # Fraction Radiant
          input_object.fields[10] = ""  # Fraction Visible
          input_object.fields[11] = ""  # Fraction Replaceable
          input_object.fields[12] = "Lights"  # End-Use Subcategory
          input_object.fields[13] = ""  # Return Air Fraction Calculated from Plenum Temperature
          input_object.fields[14] = ""  # Return Air Fraction Function of Plenum Temperature Coefficient 1
          input_object.fields[15] = ""  # Return Air Fraction Function of Plenum Temperature Coefficient 2
          add_object_to_zone(input_object, zone_name)
        end

        # ElectricEquipment
        if @value_hash['ELEC_EQUIPMENT_DENSITY'] > 0
          input_object = InputObject.new("ElectricEquipment")
          input_object.fields[1] = "#{zone_name} ElectricEquipment" # Name
          input_object.fields[2] = zone_name  # Zone Name
          input_object.fields[3] = get_schedule(@hash['ELEC_EQUIPMENT_SCHEDULE'] ) # Schedule Name
          input_object.fields[4] = "Watts/Area" # Design Level Calculation Method
          input_object.fields[5] = "" # Design Level 
          input_object.fields[6] = @value_hash['ELEC_EQUIPMENT_DENSITY'].round_to(4).to_s # Watts per Zone Floor Area
          input_object.fields[7] = "" # Watts per Person
          input_object.fields[8] = "" # Fraction Latent
          input_object.fields[9] = "" # Fraction Radiant
          input_object.fields[10] = "" # Fraction Lost
          input_object.fields[11] = "ElectricEquipment" # End-Use Subcategory
          add_object_to_zone(input_object, zone_name)
        end

        # GasEquipment
        if @value_hash['GAS_EQUIPMENT_DENSITY'] > 0
          input_object = InputObject.new("GasEquipment")
          input_object.fields[1] = "#{zone_name} GasEquipment" # Name
          input_object.fields[2] = zone_name  # Zone Name
          input_object.fields[3] = get_schedule(@hash['GAS_EQUIPMENT_SCHEDULE'] ) # Schedule Name
          input_object.fields[4] = "Watts/Area" # Design Level Calculation Method
          input_object.fields[5] = "" # Design Level 
          input_object.fields[6] = @value_hash['GAS_EQUIPMENT_DENSITY'].round_to(4).to_s # Watts per Zone Floor Area
          input_object.fields[7] = "" # Watts per Person
          input_object.fields[8] = "" # Fraction Latent
          input_object.fields[9] = "" # Fraction Radiant
          input_object.fields[10] = "" # Fraction Lost
          input_object.fields[11] = "" # Carbon Dioxide Generation Rate
          input_object.fields[12] = "GasEquipment" # End-Use Subcategory
          add_object_to_zone(input_object, zone_name)
        end

        # ZoneVentilation:DesignFlowRate
        if @value_hash['OA_PER_PERSON'] > 0
          input_object = InputObject.new("ZoneVentilation:DesignFlowRate")
          input_object.fields[1] = "#{zone_name} Ventilation per Person" # Name
          input_object.fields[2] = zone_name  # Zone Name
          input_object.fields[3] = get_schedule(@hash['OA_PER_PERSON_SCHEDULE'] ) # Schedule Name
          input_object.fields[4] = "Flow/Person" # Design Flow Rate Calculation Method
          input_object.fields[5] = "" # Design Flow Rate
          input_object.fields[6] = "" # Flow Rate per Zone Floor Area
          input_object.fields[7] = @value_hash['OA_PER_PERSON'].round_to(6).to_s # Flow Rate per Person
          input_object.fields[8] = ""  # Air Changes per Hour
          input_object.fields[9] = ""  # Ventilation Type
          input_object.fields[10] = ""  # Fan Pressure Rise
          input_object.fields[11] = ""  # Fan Total Efficiency
          input_object.fields[12] = ""  # Constant Term Coefficient
          input_object.fields[13] = ""  # Temperature Term Coefficient
          input_object.fields[14] = ""  # Velocity Term Coefficient
          input_object.fields[15] = ""  # Velocity Squared Term Coefficient
          add_object_to_zone(input_object, zone_name)
        end
        
        # ZoneVentilation:DesignFlowRate
        if @value_hash['OA_PER_AREA'] > 0 
          input_object = InputObject.new("ZoneVentilation:DesignFlowRate")
          input_object.fields[1] = "#{zone_name} Ventilation per Area" # Name
          input_object.fields[2] = zone_name  # Zone Name
          input_object.fields[3] = get_schedule(@hash['OA_PER_AREA_SCHEDULE'] ) # Schedule Name
          input_object.fields[4] = "Flow/Area" # Design Flow Rate Calculation Method
          input_object.fields[5] = "" # Design Flow Rate
          input_object.fields[6] = @value_hash['OA_PER_AREA'].round_to(6).to_s # Flow per Zone Floor Area
          input_object.fields[7] = "" # Flow Rate per Person
          input_object.fields[8] = ""  # Air Changes per Hour
          input_object.fields[9] = ""  # Ventilation Type
          input_object.fields[10] = ""  # Fan Pressure Rise
          input_object.fields[11] = ""  # Fan Total Efficiency
          input_object.fields[12] = ""  # Constant Term Coefficient
          input_object.fields[13] = ""  # Temperature Term Coefficient
          input_object.fields[14] = ""  # Velocity Term Coefficient
          input_object.fields[15] = ""  # Velocity Squared Term Coefficient
          add_object_to_zone(input_object, zone_name)
        end

        # ZoneInfiltration:DesignFlowRate
        if @value_hash['INFILTRATION_RATE'] > 0
          input_object = InputObject.new("ZoneInfiltration:DesignFlowRate")
          input_object.fields[1] = "#{zone_name} Infiltration" # Name
          input_object.fields[2] = zone_name  # Zone Name
          input_object.fields[3] = get_schedule(@hash['INFILTRATION_SCHEDULE'] ) # Schedule Name
          input_object.fields[4] = "AirChanges/Hour" # Design Flow Rate Calculation Method
          input_object.fields[5] = "" # Design Flow Rate
          input_object.fields[6] = "" # Flow per Zone Floor Area
          input_object.fields[7] = "" # Flow per Exterior Surface Area
          input_object.fields[8] = @value_hash['INFILTRATION_RATE'].round_to(4).to_s  # Air Changes per Hour
          input_object.fields[9] = "" # Constant Term Coefficient
          input_object.fields[10] = "" # Temperature Term Coefficient
          input_object.fields[11] = "" # Velocity Term Coefficient
          input_object.fields[12] = "" # Velocity Squared Term Coefficient
          add_object_to_zone(input_object, zone_name)
        end

        if @hash['ADD_IDEAL_LOADS']
          # HVACTemplate:Zone:IdealLoadsAirSystem
          input_object = InputObject.new("HVACTemplate:Zone:IdealLoadsAirSystem")
          input_object.fields[1] = zone_name  # Zone Name
          input_object.fields[2] = get_thermostat(@hash['THERMOSTAT_NAME']) # Template Thermostat Name
          add_object_to_zone(input_object, zone_name)
        end
        
        Plugin.model_manager.input_file.modified = true
 
      end
      
    end
    
    def on_last_report
      if (Plugin.platform == Platform_Windows)
        Plugin.dialog_manager.show(LastReportInterface)
        Plugin.dialog_manager.active_interface(LastReportInterface).last_report = @last_report
      else
        # mac last report web dialog not working, puts to ruby console or messagebox as a work around
        UI.messagebox @last_report,MB_MULTILINE
      end
    end
    
  end

end
