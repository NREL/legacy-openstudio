# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/dialogs/Dialogs")
require("legacy_openstudio/lib/dialogs/DialogContainers")
require("legacy_openstudio/lib/dialogs/LastReportInterface")

module LegacyOpenStudio

  class DefaultConstructionsDialog < PropertiesDialog

    def initialize(container, interface, hash)
      super
      w = Plugin.platform_select(660, 660)
      h = Plugin.platform_select(540, 580)
      @container = WindowContainer.new("Default Constructions", w, h, 150, 150)
      @container.set_file(Plugin.dir + "/lib/dialogs/html/DefaultConstructions.html")
      
      @last_report = ""
      
      add_callbacks
    end


    def add_callbacks
      super
      @container.web_dialog.add_action_callback("on_load") { on_load }
      @container.web_dialog.add_action_callback("on_open") { on_open }
      @container.web_dialog.add_action_callback("on_new_construction") { on_new_construction }
      @container.web_dialog.add_action_callback("on_save") { on_save }
      @container.web_dialog.add_action_callback("on_save_as") { on_save_as }
      @container.web_dialog.add_action_callback("on_cancel") { on_cancel }
      @container.web_dialog.add_action_callback("on_ok") { on_ok }
      @container.web_dialog.add_action_callback("on_reset_selection") { on_reset_selection }
      @container.web_dialog.add_action_callback("on_reset_model") { on_reset_model }
      @container.web_dialog.add_action_callback("on_last_report") { on_last_report }
    end
  
    # on page load
    def on_load 
      super
      update
    end
    
    def update
      
      object_names = Plugin.model_manager.construction_manager.constructions.collect { |object| object.name }
      object_names = object_names.sort
      
      set_select_options("DEFAULT_FLOOR_EXT", object_names)  
      set_select_options("DEFAULT_FLOOR_INT", object_names)  
      set_select_options("DEFAULT_WALL_EXT", object_names)  
      set_select_options("DEFAULT_WALL_INT", object_names)  
      set_select_options("DEFAULT_ROOF_EXT", object_names)  
      set_select_options("DEFAULT_ROOF_INT", object_names)  
      set_select_options("DEFAULT_WINDOW_EXT", object_names)  
      set_select_options("DEFAULT_WINDOW_INT", object_names)  
      set_select_options("DEFAULT_DOOR_EXT", object_names)  
      set_select_options("DEFAULT_DOOR_INT", object_names)    
      
      @hash['DEFAULT_FLOOR_EXT'] = Plugin.model_manager.construction_manager.default_floor_ext
      @hash['DEFAULT_FLOOR_INT'] = Plugin.model_manager.construction_manager.default_floor_int
      @hash['DEFAULT_WALL_EXT'] = Plugin.model_manager.construction_manager.default_wall_ext
      @hash['DEFAULT_WALL_INT'] = Plugin.model_manager.construction_manager.default_wall_int
      @hash['DEFAULT_ROOF_EXT'] = Plugin.model_manager.construction_manager.default_roof_ext
      @hash['DEFAULT_ROOF_INT'] = Plugin.model_manager.construction_manager.default_roof_int
      @hash['DEFAULT_WINDOW_EXT'] = Plugin.model_manager.construction_manager.default_window_ext
      @hash['DEFAULT_WINDOW_INT'] = Plugin.model_manager.construction_manager.default_window_int
      @hash['DEFAULT_DOOR_EXT'] = Plugin.model_manager.construction_manager.default_door_ext
      @hash['DEFAULT_DOOR_INT'] = Plugin.model_manager.construction_manager.default_door_int     
      @hash['DEFAULT_SAVE_PATH'] = Plugin.model_manager.construction_manager.default_save_path
      
      super
      
    end
    
    # search for and open saved preferences
    def on_open
    
      if (@hash['DEFAULT_SAVE_PATH'].empty?)
        dir = Plugin.model_manager.input_file_dir
        file_name = "*.default_constructions"      
      else
        dir = File.dirname(@hash['DEFAULT_SAVE_PATH'])
        file_name = File.basename(@hash['DEFAULT_SAVE_PATH'])
      end

      if (file_path = UI.open_panel("Locate Default Constructions Preferences", dir, file_name))
        file_path = file_path.split("\\").join("/")
      
        if (File.exists?(file_path))
          begin
            File.open(file_path, 'r') do |file|
              @hash = Marshal.load(file)
            end
            @hash['DEFAULT_SAVE_PATH'] = file_path
            report
            update

          rescue Exception => e
            UI.messagebox("Invalid default constructions preferences file, #{e}", MB_OK)
          end

        else
          UI.messagebox("Default constructions preferences file does not exist", MB_OK)
        end
      end          
    end
    
    # save preferences to file
    def on_save
      
      report
      
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
      
        @hash.each_pair do |k,v|
          puts "k = #{k} and #{k.class}, v = #{v} and #{v.class}"
        end
      
        File.open(@hash['DEFAULT_SAVE_PATH'], 'w') do |file|
          Marshal.dump(@hash, file)
        end
      rescue Exception => e
        UI.messagebox("Save failed, #{e}", MB_OK)
      end

    end
    
    # save preferences to file 
    def on_save_as
    
      if (@hash['DEFAULT_SAVE_PATH'].empty? and Plugin.model_manager.input_file.path)
        dir = Plugin.model_manager.input_file_dir
        file_name = Plugin.model_manager.input_file_name + ".default_constructions"      
      else
        dir = File.dirname(@hash['DEFAULT_SAVE_PATH'])
        file_name = File.basename(@hash['DEFAULT_SAVE_PATH']) + ".default_constructions" 
      end

      if (file_path = UI.save_panel("Save Default Constructions Preferences", dir, file_name))    
        @hash['DEFAULT_SAVE_PATH'] = file_path
        on_save
      end
  
    end
    
    # apply preferences
    def report
    
      Plugin.model_manager.construction_manager.default_floor_ext = @hash['DEFAULT_FLOOR_EXT']
      Plugin.model_manager.construction_manager.default_floor_int = @hash['DEFAULT_FLOOR_INT']
      Plugin.model_manager.construction_manager.default_wall_ext = @hash['DEFAULT_WALL_EXT']
      Plugin.model_manager.construction_manager.default_wall_int = @hash['DEFAULT_WALL_INT']
      Plugin.model_manager.construction_manager.default_roof_ext = @hash['DEFAULT_ROOF_EXT']
      Plugin.model_manager.construction_manager.default_roof_int = @hash['DEFAULT_ROOF_INT']
      Plugin.model_manager.construction_manager.default_window_ext = @hash['DEFAULT_WINDOW_EXT']
      Plugin.model_manager.construction_manager.default_window_int = @hash['DEFAULT_WINDOW_INT']
      Plugin.model_manager.construction_manager.default_door_ext = @hash['DEFAULT_DOOR_EXT']
      Plugin.model_manager.construction_manager.default_door_int = @hash['DEFAULT_DOOR_INT']    
      Plugin.model_manager.construction_manager.default_save_path = @hash['DEFAULT_SAVE_PATH']
      
      super
    end
    
    def on_reset_model
      model = Sketchup.active_model
      model.selection.clear
      model.entities.each {|e| model.selection.add(e)}
      reset(model.selection)   
      model.selection.clear
    end
    
    def on_reset_selection
      model = Sketchup.active_model
      reset(model.selection)
    end
   
   
    # reset selected items to have default constructions
    def reset(selection)
    
      report
      
      if selection.empty?
        UI.messagebox("Selection is empty, please select objects to reset to Default Constructions or choose 'Apply to Entire Model'.")
        return
      end
      
      result = UI.messagebox(
"Warning this will reset surfaces and subsurfaces 
within the selection to their defaults.\n
This operation cannot be undone.\n  
Do you want to continue?", MB_OKCANCEL)   
      
      @last_report = "Default Construction Report:\n"
      @last_report << "BuildingSurface:Detailed, Zone, Previous Construction, New Construction\n"
      
      model = Sketchup.active_model
      model.start_operation("Reset to Default Constructions", true)
      
      reset_names = []
      other_names = []
      Plugin.model_manager.base_surfaces.each do |base_surface|
        if base_surface.in_selection?(selection)
          default_construction = base_surface.default_construction
          @last_report << "'#{base_surface.name}, #{base_surface.input_object.fields[4]}, #{base_surface.input_object.fields[3]}, #{default_construction}\n"
          base_surface.input_object.fields[3] = default_construction
          
          reset_names << base_surface.name
          if base_surface.input_object.fields[5].to_s == 'Surface' and not base_surface.input_object.fields[6].nil? and not base_surface.input_object.fields[6].to_s.empty?
            other_names << base_surface.input_object.fields[6].to_s
          end
        end
      end
      
      # now set any matching surfaces not in selection
      Plugin.model_manager.base_surfaces.each do |base_surface|
        if not reset_names.include?(base_surface.name) and other_names.include?(base_surface.name)
          default_construction = base_surface.default_construction
          @last_report << "'#{base_surface.name}, #{base_surface.input_object.fields[4]}, #{base_surface.input_object.fields[3]}, #{default_construction}\n"
          base_surface.input_object.fields[3] = default_construction
        end
      end
      
      @last_report << "\nFenestrationSurface:Detailed, BuildingSurface:Detailed, Previous Construction, New Construction\n"
      
      reset_names = []
      other_names = []
      Plugin.model_manager.sub_surfaces.each do |sub_surface|
        if sub_surface.in_selection?(selection)
          default_construction = sub_surface.default_construction
          @last_report << "'#{sub_surface.name}, #{sub_surface.input_object.fields[4]}, #{sub_surface.input_object.fields[3]}, #{default_construction}\n"
          sub_surface.input_object.fields[3] = default_construction
          
          reset_names << sub_surface.name
          if not sub_surface.input_object.fields[5].nil? and not sub_surface.input_object.fields[5].to_s.empty?
            other_names << sub_surface.input_object.fields[5].to_s
          end
        end
      end     
      
      # now set any matching subsurfaces not in selection
      Plugin.model_manager.sub_surfaces.each do |sub_surface|
        if not reset_names.include?(sub_surface.name) and other_names.include?(sub_surface.name)
          default_construction = sub_surface.default_construction
          @last_report << "'#{sub_surface.name}, #{sub_surface.input_object.fields[4]}, #{sub_surface.input_object.fields[3]}, #{default_construction}\n"
          sub_surface.input_object.fields[3] = default_construction
        end
      end
      
      Plugin.model_manager.input_file.modified = true
      
      model.commit_operation
      
    end    
    
    # just close
    def on_cancel
      close
    end
    
    # apply and close
    def on_ok
      report
      close
    end
    
    def on_new_construction
      report
      Plugin.model_manager.construction_manager.new_construction_stub
      update
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
