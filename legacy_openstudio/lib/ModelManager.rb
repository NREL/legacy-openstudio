5# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/ConstructionManager")
require("legacy_openstudio/lib/ScheduleManager")
require("legacy_openstudio/lib/ResultsManager")

require("legacy_openstudio/lib/dialogs/ProgressDialog")

require("legacy_openstudio/lib/inputfile/InputFile")

require("legacy_openstudio/lib/interfaces/ModelInterface")

require("legacy_openstudio/lib/observers/AppObserver")
require("legacy_openstudio/lib/observers/ModelObserver")
require("legacy_openstudio/lib/observers/SelectionObserver")
require("legacy_openstudio/lib/observers/UnitsObserver")


module LegacyOpenStudio

  class ModelManager
   
    attr_accessor :guid, :units_system, :units_hash, :length_precision, :angle_precision, :construction_manager, :schedule_manager, :results_manager, :zone_loads_manager
    attr_accessor :input_file, :components, :weather_file, :model_interface, :rendering_mode, :unviewed_errors, :model_observer, :selection_observer


    def initialize
      @model_interface = nil
      @guid = Sketchup.active_model.guid  # Used to verify if there is a new model or just a change of model objects.
      @error_log = ""
      @unviewed_errors = false
      @rendering_mode = 0
    end


    # Have to separate 'start' from 'initialize' because some of the methods that eventually get called try to reference
    # Plugin.model_manager...which does not exist until it 'initialize' returns to the Plugin object.
    # Some things need to be rearranged in ResultsManager to fix this dependency.
    def start
      load_default_attributes
      initialize_units_options

      @construction_manager = ConstructionManager.new
      @schedule_manager = ScheduleManager.new
      @results_manager = ResultsManager.new  # Requires model_manager in 'initialize'
      
      @model_observer = ModelObserver.new
      Sketchup.active_model.add_observer(@model_observer)
      
      @selection_observer = SelectionObserver.new
      Sketchup.active_model.selection.add_observer(@selection_observer)

      @model_interface = ModelInterface.new

      attach_input_file
      attach_weather_file
    end


    def attach_input_file
      if (path = @model_interface.model.input_file_path)
        if (File.exist?(path))
          open_input_file(path)
          return
        else
          message = "Cannot locate the attached EnergyPlus input file at:\n" + path +
            "\nDo you want to browse for the EnergyPlus input file?\n\n" +
            "Click YES, if you want to browse for the input file.\n" +
            "Click NO, if you want to detach the object references and start a new input file.\n"
        end

      else
        # Check for EnergyPlus groups even though there is no IDF file attached.
        # NOTE:  This can happen if the user was prompted to save the IDF for the first time
        #        when SketchUp exits or opens a new model.
        if (not @model_interface.has_surface_groups?)
          new_input_file
          return
        else
          message = "EnergyPlus object references were detected, but no input file is attached.\n" +
            "Do you want to browse for an existing EnergyPlus input file to reattach?\n\n" +
            "Click YES, if you want to reattach an input file.\n" +
            "Click NO, if you want to detach the object references and start a new input file.\n"
        end
      end


      button = UI.messagebox(message, MB_YESNO)

      if (button == 6)  # YES
        if (path = UI.open_panel("Open EnergyPlus Input File", File.dirname(@model_interface.model_path), "*.idf; *.imf"))
          open_input_file(path)
          return
        end

      elsif (button == 7)  # NO
        button = UI.messagebox("Do you also want to erase all of the SketchUp entities that were associated with EnergyPlus objects?", MB_YESNO)

        if (button == 6)  # YES
          @model_interface.erase_model
        end

        new_input_file
      end
    end


    def attach_weather_file
      # open and check weather file
    end


    def inspect
      return(to_s)
    end


    def model_name
      if (@model_interface.model_path.empty?)
        name = "Untitled"
      else
        name = File.basename(@model_interface.model_path, ".skp")
      end
      return(name)
    end


    def input_file_attached?
      return(not @input_file.path.nil?)
    end


    def input_file_name
      if (input_file_attached?)
        name = File.basename(@input_file.path)
      else
        name = File.basename(model_name) + ".idf"
      end
      return(name)
    end


    def input_file_dir
      if (input_file_attached?)
        dir = File.dirname(@input_file.path)
      elsif (not @model_interface.model_path.empty?)
        dir = File.dirname(@model_interface.model_path)
      else
        dir = Plugin.read_pref("Last Input File Dir")
      end
      return(dir)
    end


    def new_input_file
      open_input_file(Plugin.dir + "/NewFileTemplate.idf")
      @input_file.path = nil
      @input_file.modified = false
      @model_interface.on_change_input_file_path
      @construction_manager.reset_defaults
      @construction_manager.check_defaults
    end


    def open_input_file(path)
      success = false

      if (path.nil?)
        puts "ModelManager.open_input_file:  nil path"
      elsif (not File.exist?(path))
        puts "ModelManager.open_input_file:  bad path"
      else
        progress_dialog = ProgressDialog.new

        begin
          @input_file = InputFile.open(Plugin.data_dictionary, path, Proc.new { |percent, message| progress_dialog.update_progress(percent, message) })

          if (@input_file)
            @model_interface = ModelInterface.new(@input_file)
            @model_interface.draw_model(Proc.new { |percent, message| progress_dialog.update_progress(percent, message) })
            
            if path != Plugin.dir + "/NewFileTemplate.idf"
              Sketchup.active_model.active_view.zoom_extents
            end
          end
          
          @construction_manager.reset_defaults
          @construction_manager.check_defaults
        ensure
          progress_dialog.destroy
        end
        
        success = true
      end

      # This is probably not the optimal place for this.
      # Trying to keep GUI out of this class.
      if (success)
        Plugin.dialog_manager.update_all if (Plugin.dialog_manager)

        if (@unviewed_errors)
          show_errors
        end
      end

      return(success)
    end


    def merge_input_file(path)
      # Should be able to make 'merge_input_file' nearly identical to 'open_input_file'

      if (path.nil?)
        puts "ModelManager.merge_input_file:  nil path"
      elsif (not File.exist?(path))
        puts "ModelManager.merge_input_file:  bad path"
      else
        @input_file.merge(path)
        @model_interface.draw_model
        Sketchup.active_model.active_view.zoom_extents
      end
    end


    def save_input_file(path)
      @input_file.path = path
      @model_interface.on_change_input_file_path

      if (Sketchup.active_model)
        progress_dialog = ProgressDialog.new

        begin
          @input_file.write(path, Proc.new { |percent, message| progress_dialog.update_progress(percent, message) })
        ensure
          progress_dialog.destroy
        end

      else
        # SketchUp has already shutdown!
        # Do the write without a progress dialog.
        @input_file.write(path)
      end
    end


    def close_input_file
      @error_log = ""
      @unviewed_errors = false
      
      # Unlock or otherwise release the input file so that other programs can use it
      # - might be a combination of flock and/or chmod:
      #file = File.open(@path, 'r')
      #file.chmod(0644)  # set to read/write
      #file.flock(File::LOCK_UN)  # unlock
      #file.close
    end


    def detach_input_file(erase = true)
      @model_interface.on_change_input_file_path  # input_file.path should be nil already

      if (erase)
        @model_interface.erase_model
      else
        @model_interface.clean_model
      end
    end


    def initialize_units_options
      units_options_provider = Sketchup.active_model.options["UnitsOptions"]
      units_options_provider.add_observer(UnitsObserver.new)

      case (units_options_provider['LengthUnit'])
      when 0, 1
        @units_system = "IP"
      when 2, 3, 4
        @units_system = "SI"
      end

      @units_hash = Hash.new
      @units_hash['m'] = ["(m)", "(ft)", 1.0]
      @units_hash['m2'] = ["(m" + 178.chr + ")", "(ft" + 178.chr + ")", 1.0]
      @units_hash['m3'] = ["(m" + 179.chr + ")", "(ft" + 179.chr + ")", 1.0]
      @units_hash['People/100m2'] = ["(Number of People/100 m" + 178.chr + ")", "(Number of People/1000 ft" + 178.chr + ")", 1.0]
      @units_hash['W/m2'] = ["(W/m" + 178.chr + ")", "(W/ft" + 178.chr + ")", 1.0]
      @units_hash['W/linear m'] = ["(W/linear m)", "(W/linear ft)", 1.0]
      @units_hash['m2/TDD'] = ["(m" + 178.chr + "/TDD)", "(f" + 178.chr + "/TDD)", 1.0]
      @units_hash['lux'] = ["(lux)", "(footcandles)", 1.0]
      @units_hash['L'] = ["(Liters)", "(Gallons)", 1.0]
      @units_hash['C'] = ["(" + 176.chr + "C)", "(" + 176.chr + "F)", 1.0]
      @units_hash['L/sec'] = ["(L/sec)", "(cfm)", 1.0]
      @units_hash['L/sec/person'] = ["(L/sec/person" + 178.chr + ")", "(cfm/person)", 1.0]
      @units_hash['L/sec/m2'] = ["(L/sec/m" + 178.chr + ")", "(cfm/ft" + 178.chr + ")", 1.0]
      # Expand as necessary...

      @length_precision = units_options_provider['LengthPrecision']
      
      @angle_precision = units_options_provider['AnglePrecision']
    end


    def get_attribute(name)
      return(Sketchup.active_model.get_attribute("OpenStudio", name))
    end


    def set_attribute(name, value)
      Sketchup.active_model.set_attribute("OpenStudio", name, value)
    end


    def default_attributes
      hash = Hash.new
      
      # Run Simulation attributes
      hash['Weather File Path'] = ""
      hash['Report ABUPS'] = true
      hash['ABUPS Format'] = "HTML"
      hash['ABUPS Units'] = "SI"
      hash['Report User Variables'] = true
      hash['Report Sql'] = false
      hash['Report Zone Temps'] = false
      hash['Report Surface Temps'] = false
      hash['Close Shell'] = true
      hash['Show ERR'] = true
      hash['Show ABUPS'] = true
      hash['Show CSV'] = false

      # Output file and rendering attributes
      hash['Output File Path'] = ""
      hash['Output File Last Modified'] = nil
      hash['Run Period'] = "0"
      hash['Variable Type'] = "SURFACE"
      hash['Outside Variable'] = ""
      hash['Inside Variable'] = ""
      hash['Appearance'] = "COLOR"
      hash['Match Range'] = true
      hash['Range Minimum'] = ""
      hash['Range Maximum'] = ""
      hash['Interpolate'] = false


      # Others:
      # current view mode
      # windows open?
      
      # Animation settings
      
      return(hash)
    end


    def load_default_attributes
      # Create and set default attributes for any that might not be saved on the model already.
      # For example, for every new model, or update of a model with a new version.
      default_hash = default_attributes
      for key in default_hash.keys
        if (get_attribute(key).nil?)
          set_attribute(key, default_hash[key])
        end
      end
    end


    def destroy
      Plugin.dialog_manager.close_all
      close_input_file
    end


    def add_error(error_string)
      @error_log += error_string
      @unviewed_errors = true
    end


    def show_errors
      if (@error_log.empty?)
        @error_log = "No errors or warnings."
      end
      UI.messagebox(@error_log, MB_MULTILINE, Plugin.name + ":  Input File Errors And Warnings")
      @unviewed_errors = false
    end


    def selected_drawing_interface
      drawing_interface = nil
      if (Sketchup.active_model)
        if (Sketchup.active_model.selection.empty?)
          parent = Sketchup.active_model.active_entities.parent
          if (parent.class == Sketchup::ComponentDefinition)
            # Gets the SurfaceGroup interface that is currently open for editing
            drawing_interface = parent.instances.first.drawing_interface
          else
            drawing_interface = building
          end

        else
          Sketchup.active_model.selection.each do |entity|
            if (entity.drawing_interface and (entity.class == Sketchup::Group or entity.class == Sketchup::Face or entity.class == Sketchup::ComponentInstance))

              # Check for entities that have been copied into a non-EnergyPlus group and clean them.
              if (entity.parent.class == Sketchup::ComponentDefinition and not entity.parent.instances.first.drawing_interface)
                entity.drawing_interface = nil
                entity.input_object_key = nil
              end

              drawing_interface = entity.drawing_interface
            end
          end
        end
      end
      return(drawing_interface)
    end


    def selection_changed
      #puts "selection_changed"

      # Note: This gets called twice for every click, e.g., changed from item A to item B selected.
      # Reason is that selection cleared is also calling this, but drawing interface is nil.
      if (Plugin.dialog_manager.active_interface(ObjectInfoInterface) and Sketchup.active_model.tools.active_tool_id == 21022)
      #if (Plugin.dialog_manager.active_interface(ObjectInfoInterface) and Sketchup.active_model.tools.active_tool_name == "SelectionTool")
        # Mac bug:  active_tool_name returns as "ctionTool" on the Mac.  Only active_tool_id is cross-platform.
        Plugin.dialog_manager.update(ObjectInfoInterface)
      end
    end


    def surface_geometry
      return(@model_interface.children.find { |child| child.class == SurfaceGeometry })
    end


    def building
      return(@model_interface.children.find { |child| child.class == Building })
    end


    def location
      return(@model_interface.children.find { |child| child.class == Location })
    end


    def zones
      return(@model_interface.children.find_all { |child| child.class == Zone })
    end


    def shading_groups
      return(@model_interface.children.find_all { |child| child.class == DetachedShadingGroup })
    end


    def base_surfaces
      return(@model_interface.recurse_children.find_all { |child| child.class == BaseSurface })
    end


    def sub_surfaces
      return(@model_interface.recurse_children.find_all { |child| child.class == SubSurface })
    end


    def shading_surfaces
      return(@model_interface.recurse_children.find_all { |child| child.class == AttachedShadingSurface or child.class == DetachedShadingSurface })
    end


    def all_surfaces
      return(@model_interface.recurse_children.find_all { |child| child.class == BaseSurface or child.class == SubSurface or child.class == AttachedShadingSurface or child.class == DetachedShadingSurface })
    end
    
    def output_illuminance_maps
      return(@model_interface.recurse_children.find_all { |child| child.class == OutputIlluminanceMap })
    end

    def daylighting_controls
      return(@model_interface.recurse_children.find_all { |child| child.class == DaylightingControls })
    end
   
    def relative_coordinates?
      if (drawing_interface = surface_geometry)
        return(drawing_interface.input_object.fields[3] == "Relative")
      else
        puts "ModelManager.relative_coordinates?:  GlobalGeometryRules is missing"
        return(false)
      end
    end
    
    def relative_daylighting_coordinates?
      if (drawing_interface = surface_geometry)
        if (drawing_interface.input_object.fields[4])
          return(drawing_interface.input_object.fields[4] == "Relative")
        else
          return(true) # default
        end
      else
        puts "ModelManager.relative_coordinates?:  GlobalGeometryRules is missing"
        return(false)
      end
    end

    def paint
      time = Sketchup.active_model.shadow_info.time

      if (output_file = @results_manager.output_file)
        run_period = output_file.run_periods[@results_manager.run_period_index]

        #outside_data_set = @results_manager.outside_data_set
        #inside_data_set = @results_manager.inside_data_set

        range_min = @results_manager.range_minimum.to_f
        range_max = @results_manager.range_maximum.to_f
        
        rendering_appearance = @results_manager.rendering_appearance
        interpolate = @results_manager.interpolate
        normalize = @results_manager.normalize
      end

      # Suspicious that recursion is causing a major slow down here.
      # It seems to do recursion in a multithreaded way so that current thread completes but the rendering mode button does not update
      # until all the recursive threads are finished.
      for child in @model_interface.recurse_children
        next if (not child.respond_to?(:outside_variable_key))
        
        had_observers = child.remove_observers

        # added the or statement for render by boundary, layer, normal
        if (@rendering_mode == 0)
          child.paint_entity  # Non-surface drawing interfaces do not implement 'paint_entity'.
        elsif (@rendering_mode == 2)
          child.paint_boundary
        elsif (@rendering_mode == 3)
          child.paint_layer
        elsif (@rendering_mode == 4)
          child.paint_normal
        else
          # get data details

          # would be nice to do the paint once...then have a database of the materials...animations and updates can change color of materials
          # not having to call paint everytime.

          if (child.outside_variable_key)
            outside_value = run_period.data_series[child.outside_variable_key].value_at(time, interpolate)
            outside_variable_def = run_period.data_series[child.outside_variable_key].variable_def
            
            if (not outside_value.nil?) and normalize
              # Need better method here
              if (Plugin.model_manager.units_system == "SI")
                outside_value = outside_value / (child.outside_normalization.to_m.to_m)
              else
                outside_value = outside_value / (child.outside_normalization.to_feet.to_feet)
              end
            end
          else
            outside_value = nil
            outside_variable_def = nil
          end
          #puts "val=" + outside_value.to_s

          if (outside_value.nil?)
            color = Sketchup::Color.new(255, 255, 255, 1.0)  # No data--paint white
            texture = nil

          elsif (range_max == range_min)
            color = Sketchup::Color.new(255, 255, 255, 1.0)  # No data--paint white
            texture = nil

          elsif (outside_value < range_min)
            color = nil
            if (rendering_appearance == "COLOR")
              texture = Plugin.dir + "lib/resources/crosshatch_blue.bmp"
            else
              texture = Plugin.dir + "lib/resources/crosshatch_black.bmp"
            end

          elsif (outside_value > range_max)
            color = nil
            if (rendering_appearance == "COLOR")
              texture = Plugin.dir + "lib/resources/crosshatch_red.bmp"
            else
              texture = Plugin.dir + "lib/resources/crosshatch_white.bmp"
            end

          else
            color = Sketchup::Color.new
            if (rendering_appearance == "COLOR")
              h = 240.0 * (range_max - outside_value) / (range_max - range_min)
              color.hsba = [h, 100, 100, 1.0]
            else  # Gray scale
              b = 90.0 - 70.0 * (range_max - outside_value) / (range_max - range_min)
              color.hsba = [0, 0, b, 1.0]
            end
            texture = nil
          end
          child.outside_value = outside_value
          child.outside_color = color
          child.outside_texture = texture
          child.outside_variable_def = outside_variable_def

          if (child.inside_variable_key)
            inside_value = run_period.data_series[child.inside_variable_key].value_at(time, interpolate)
            inside_variable_def = run_period.data_series[child.inside_variable_key].variable_def
            
            if (not inside_value.nil?) and normalize
              # Need better method here
              if (Plugin.model_manager.units_system == "SI")
                inside_value = inside_value / (child.inside_normalization.to_m.to_m)
              else
                inside_value = inside_value / (child.inside_normalization.to_feet.to_feet)
              end
            end
          else
            inside_value = nil
            inside_variable_def = nil
          end
          #puts "val=" + outside_value.to_s

          if (inside_value.nil?)
            color = Sketchup::Color.new(255, 255, 255, 1.0)  # No data--paint white
            texture = nil
            
          elsif (range_max == range_min)
            color = Sketchup::Color.new(255, 255, 255, 1.0)  # No data--paint white
            texture = nil

          elsif (inside_value < range_min)
            color = nil
            if (rendering_appearance == "COLOR")
              texture = Plugin.dir + "lib/resources/crosshatch_blue.bmp"
            else
              texture = Plugin.dir + "lib/resources/crosshatch_black.bmp"
            end

          elsif (inside_value > range_max)
            color = nil
            if (rendering_appearance == "COLOR")
              texture = Plugin.dir + "lib/resources/crosshatch_red.bmp"
            else
              texture = Plugin.dir + "lib/resources/crosshatch_white.bmp"
            end

          else
            color = Sketchup::Color.new
            if (rendering_appearance == "COLOR")
              h = 240.0 * (range_max - inside_value) / (range_max - range_min)
              color.hsba = [h, 100, 100, 1.0]
            else  # Gray scale
              b = 90.0 - 70.0 * (range_max - inside_value) / (range_max - range_min)
              color.hsba = [0, 0, b, 1.0]
            end
            texture = nil
          end
          child.inside_value = inside_value
          child.inside_color = color
          child.inside_texture = texture
          child.inside_variable_def = inside_variable_def

          child.paint_data
        end
        
        child.add_observers if had_observers
        
      end
    
    end


    def update_surface_variable_keys
      # variable keys should be assigned as soon as Rendering Settings are applied

      outside_data_set = @results_manager.outside_data_set
      inside_data_set = @results_manager.inside_data_set      

      if (outside_data_set and inside_data_set)

        # kludgy way to get variable name (without the frequency...e.g., the set name)
        outside_variable_name = outside_data_set.data_series[0].variable_def.name
        inside_variable_name = inside_data_set.data_series[0].variable_def.name

        if (@results_manager.variable_type == "SURFACE")
          for child in @model_interface.recurse_children
            if (child.respond_to?(:outside_variable_key))
              surface = child

              outside_variable_key = @results_manager.output_file.get_variable_key(outside_variable_name, surface.input_object.name.upcase)
              surface.outside_variable_key = outside_variable_key
              surface.outside_normalization = surface.area

              inside_variable_key = @results_manager.output_file.get_variable_key(inside_variable_name, surface.input_object.name.upcase)
              surface.inside_variable_key = inside_variable_key
              surface.inside_normalization = surface.area
              
            end
          end

        else  #(@results_manager.variable_type == "ZONE")

          for zone in self.zones
            outside_variable_key = @results_manager.output_file.get_variable_key(outside_variable_name, zone.input_object.name.upcase)
            inside_variable_key = @results_manager.output_file.get_variable_key(inside_variable_name, zone.input_object.name.upcase)

            for base_surface in zone.children
              if (base_surface.respond_to?(:outside_variable_key))
                base_surface.outside_variable_key = outside_variable_key
                base_surface.inside_variable_key = inside_variable_key 
              
                base_surface.outside_normalization = zone.unit_floor_area
                base_surface.inside_normalization = zone.unit_floor_area

                for sub_surface in base_surface.children
                  sub_surface.outside_variable_key = outside_variable_key
                  sub_surface.inside_variable_key = inside_variable_key 
                
                  sub_surface.outside_normalization = zone.unit_floor_area
                  sub_surface.inside_normalization = zone.unit_floor_area
                end
              end
            end
          end

          for surface in self.shading_surfaces
            surface.outside_variable_key = nil
            surface.inside_variable_key = nil
          end

        end
      end

    end

    def set_mode(mode)
      @rendering_mode = mode
      paint

       model = Sketchup.active_model
       renderingoptions = model.rendering_options
       # add if statement (don't change if in  color by normal)
       if (@rendering_mode == 4)
       else
          #change RenderMode to 2 (so you can see material)
          render_mode_value = renderingoptions["RenderMode"] = 2  
       end
       # add if statement (don't chagne if in color by layer)
       if (@rendering_mode == 3)
       else
        #change DisplayColorByLayer to false (so you can see material)
          color_by_layer_value = renderingoptions["DisplayColorByLayer"] = false
       end
      end

    # this will make materials visible, but won't change the set_mode (mode)
    def set_mode_only

       model = Sketchup.active_model
       renderingoptions = model.rendering_options
       #change RenderMode to 2 (so you can see material)
       render_mode_value = renderingoptions["RenderMode"] = 2
       #change DisplayColorByLayer to false (so you can see material)
       color_by_layer_value = renderingoptions["DisplayColorByLayer"] = false
    end


  end
  
end
