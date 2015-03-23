# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/dialogs/Dialogs")
require("legacy_openstudio/lib/dialogs/DialogContainers")


module LegacyOpenStudio

  class RenderingSettingsDialog < PropertiesDialog

    attr_accessor :output_file

    def initialize(container, interface, hash)
      super
      w = Plugin.platform_select(489, 560)
      h = Plugin.platform_select(560, 640)
      @container = WindowContainer.new("Rendering Settings", w, h, 150, 150)
      @container.set_file(Plugin.dir + "/lib/dialogs/html/RenderingSettings.html")

      @output_file = Plugin.model_manager.results_manager.output_file
      
   # check if file was modified
   
      @run_period_index = 0

      @surface_variables = []
      @zone_variables = []
      
      @outside_units = ""
      @outside_min = ""
      @outside_max = ""
      @inside_units = ""
      @inside_min = ""
      @inside_max = ""

      add_callbacks
    end

    def add_callbacks
      super
      @container.web_dialog.add_action_callback("on_browse") { on_browse }
      @container.web_dialog.add_action_callback("on_change_run_period") { on_change_run_period }
      @container.web_dialog.add_action_callback("on_click_variable_type") { on_click_variable_type }
      @container.web_dialog.add_action_callback("on_click_normalize") { on_click_normalize }
      @container.web_dialog.add_action_callback("on_change_outside_variable") { on_change_outside_variable }
      @container.web_dialog.add_action_callback("on_change_inside_variable") { on_change_inside_variable }
      @container.web_dialog.add_action_callback("on_click_match_range") { on_click_match_range }
      @container.web_dialog.add_action_callback("on_change_appearance") { on_change_appearance }
    end

    def on_load
      super
      on_change_output_file 
      on_click_variable_type
      on_click_match_range
      on_change_appearance
      update

      if (Plugin.platform == Platform_Mac)
        @container.execute_function("invalidate()")  # Force the WebDialog to redraw
      end
    end

    def on_browse
      if (@hash['OUTPUT_FILE_PATH'].empty?)
        dir = Plugin.model_manager.input_file_dir
        file_name = "*.eso"      
      else
        dir = File.dirname(@hash['OUTPUT_FILE_PATH'])
        file_name = File.basename(@hash['OUTPUT_FILE_PATH'])
      end

      if (output_file_path = UI.open_panel("Locate Output File", dir, file_name))
      
        # if user selects .cache file help them out
        output_file_path.gsub!('.eso.cache', '.eso')

        # could replace with a single method called here and in report
        if (File.exists?(output_file_path))
          output_file_path = output_file_path.split("\\").join("/")
          @hash['OUTPUT_FILE_PATH'] = output_file_path
          @output_file = ResultsManager.process_output_file(output_file_path)  # Does not change the ResultsManager attributes--it's a class method
          Plugin.model_manager.results_manager.run_period_index = 0
          @hash['RUN_PERIOD'] = 0
          @run_period_index = 0
          on_change_output_file
          update
        end
      end
    end

    def on_change_output_file
      if (@output_file)
        run_period_names = []
        run_period_indices = []
        count = 0
        @output_file.run_periods.each { |run_period|
          run_period_names << run_period.display_name
          run_period_indices << count.to_s
          count += 1
        }
        if (run_period_indices.empty?)
          run_period_indices = ['']
        end
        set_select_options("RUN_PERIOD", run_period_indices, run_period_names)
        
        on_change_run_period
        on_click_variable_type
      end
    end

    def on_change_run_period
      if (@output_file)
        @run_period_index = @hash['RUN_PERIOD'].to_i
        run_period = @output_file.run_periods[@run_period_index]
        if (run_period)
          set_element_value("LATITUDE", run_period.latitude)
          set_element_value("LONGITUDE", run_period.longitude)
          set_element_value("TIME_ZONE", run_period.time_zone)
          set_element_value("ELEVATION", run_period.elevation)
        end
        on_change_outside_variable
        on_change_inside_variable
      end
    end

    def on_click_variable_type
    
      if (@hash['VARIABLE_TYPE'] == "SURFACE")
        set_element_value("NORMALIZE_VARIABLE_BY", "net surface area")
        variable_defs = get_surface_variables.to_a
      else
        set_element_value("NORMALIZE_VARIABLE_BY", "zone floor area")
        variable_defs = get_zone_variables.to_a
      end

      if (not variable_defs.nil?)
        variable_defs.sort! { |a, b| a.set_name <=> b.set_name }

        variable_names = []
        variable_defs.each { |variable_def|
          variable_names += [ variable_def.set_name ]
        }
        if (variable_names.empty?)
          variable_names = ['']
        end

        set_select_options("OUTSIDE_VARIABLE", variable_names)
        set_select_options("INSIDE_VARIABLE", variable_names)
        
        if (variable_names.index(@hash['OUTSIDE_VARIABLE']))
          set_element_value("OUTSIDE_VARIABLE", @hash['OUTSIDE_VARIABLE'])
        else
          @hash['OUTSIDE_VARIABLE'] = variable_names[0]
          set_element_value("OUTSIDE_VARIABLE", variable_names[0])
        end
        on_change_outside_variable

        if (variable_names.index(@hash['INSIDE_VARIABLE']))
          set_element_value("INSIDE_VARIABLE", @hash['INSIDE_VARIABLE'])
        else
          @hash['INSIDE_VARIABLE'] = variable_names[0]
          set_element_value("INSIDE_VARIABLE", variable_names[0])
        end
        on_change_inside_variable

      end 
      
    end
    
    def on_click_normalize

      if @hash['NORMALIZE']
        # disable match range
        @hash['MATCH_RANGE'] = false
        set_element_value("MATCH_RANGE", @hash['MATCH_RANGE'])
        disable_element('MATCH_RANGE')
        enable_element('RANGE_MINIMUM')
        enable_element('RANGE_MAXIMUM')
        
        normalize_suffix = ""
        if (Plugin.model_manager.units_system == "SI")
          normalize_suffix = "/m2"
        else
          normalize_suffix = "/ft2"
        end
        
        set_element_value("OUTSIDE_UNITS", @outside_units + normalize_suffix)
        set_element_value("INSIDE_UNITS", @inside_units + normalize_suffix)
      else
        # enable match range
        @hash['MATCH_RANGE'] = true
        set_element_value('MATCH_RANGE', @hash['MATCH_RANGE'])
        enable_element('MATCH_RANGE')
       
        set_element_value("OUTSIDE_UNITS", @outside_units)
        set_element_value("INSIDE_UNITS", @inside_units)
        
        on_click_match_range
      end
    end

    def on_change_outside_variable
      range = get_variable_range(@hash['OUTSIDE_VARIABLE'])
      if (range)
        @outside_units = range[0].to_s
        @outside_min = "%0.2f" % range[1].to_s
        @outside_max = "%0.2f" % range[2].to_s
      else
        @outside_units = ""
        @outside_min = ""
        @outside_max = ""
      end

      set_element_value("OUTSIDE_MINIMUM", @outside_min)
      set_element_value("OUTSIDE_MAXIMUM", @outside_max)  
      
      if (@hash['VARIABLE_TYPE'] != "SURFACE")
        @hash['INSIDE_VARIABLE'] = @hash['OUTSIDE_VARIABLE']
        on_change_inside_variable
      else
        on_click_match_range
        on_click_normalize
      end
      
    end

    def on_change_inside_variable
      range = get_variable_range(@hash['INSIDE_VARIABLE'])
      if (range)
        @inside_units = range[0].to_s
        @inside_min = "%0.2f" % range[1].to_s
        @inside_max = "%0.2f" % range[2].to_s
      else
        @inside_units = ""
        @inside_min = ""
        @inside_max = ""
      end

      set_element_value("INSIDE_MINIMUM", @inside_min)
      set_element_value("INSIDE_MAXIMUM", @inside_max)
      
      on_click_match_range
      on_click_normalize
    end

    def on_change_appearance
      if (@hash['APPEARANCE'] == "COLOR")
        set_element_source("SCALE", "colorscale.bmp")
      else
        set_element_source("SCALE", "grayscale.bmp")
      end
    end

    def on_click_match_range
      if (@hash['MATCH_RANGE'])
        set_range_min_max
        disable_element("RANGE_MINIMUM")
        disable_element("RANGE_MAXIMUM")
      else
        enable_element("RANGE_MINIMUM")
        enable_element("RANGE_MAXIMUM")
      end
    end

    def set_range_min_max
      if (@outside_min.empty? and @inside_min.empty?)
        @hash['RANGE_MINIMUM'] = ""
      elsif (@outside_min.empty?)
        @hash['RANGE_MINIMUM'] = @inside_min
      elsif (@inside_min.empty?)
        @hash['RANGE_MINIMUM'] = @outside_min
      else
        @hash['RANGE_MINIMUM'] = ([@outside_min.to_f, @inside_min.to_f].min).to_s
      end

      set_element_value("RANGE_MINIMUM", @hash['RANGE_MINIMUM'])

      if (@outside_max.empty? and @inside_max.empty?)
        @hash['RANGE_MAXIMUM'] = ""
      elsif (@outside_max.empty?)
        @hash['RANGE_MAXIMUM'] = @inside_max
      elsif (@inside_max.empty?)
        @hash['RANGE_MAXIMUM'] = @outside_max
      else
        @hash['RANGE_MAXIMUM'] = ([@outside_max.to_f, @inside_max.to_f].max).to_s
      end
      
      set_element_value("RANGE_MAXIMUM", @hash['RANGE_MAXIMUM'])
    end

    def get_surface_variables
      surface_variables = []

      if (@output_file)
        surface_names = Plugin.model_manager.input_file.find_objects_by_class_name("BUILDINGSURFACE:DETAILED", "FENESTRATIONSURFACE:DETAILED",
          "SHADING:ZONE:DETAILED", "SHADING:BUILDING:DETAILED", "SHADING:SITE:DETAILED").to_a.collect { |surface| surface.name.upcase }

        for variable_def in @output_file.variable_defs.values
          if (surface_names.index(variable_def.object_name))
          
            # Check if the same variable name is already in the array
            found = false
            for surface_variable in surface_variables
              if (surface_variable.set_name == variable_def.set_name)
                found = true
                break
              end
            end

            if (not found)
              surface_variables << variable_def
            end
          end
        end
      end

      return(surface_variables)
    end

    def get_zone_variables
      zone_variables = []

      if (@output_file)
        zone_names = Plugin.model_manager.input_file.find_objects_by_class_name("ZONE").to_a.collect { |zone| zone.name.upcase }

        for variable_def in @output_file.variable_defs.values
          
          if (zone_names.index(variable_def.object_name))

            # Check if the same variable name is already in the array
            found = false
            for zone_variable in zone_variables
              if (zone_variable.set_name == variable_def.set_name)
                found = true
                break
              end
            end

            if (not found)
              zone_variables << variable_def
            end
          end
        end
      end

      return(zone_variables)
    end

    def get_variable_range(set_name)
      # Returns the range of values across all variables with the same name.
      if (@output_file)
        if (data_set = @output_file.run_periods[@run_period_index].data_sets[set_name])
          units = data_set.units
          minimum = data_set.min
          maximum = data_set.max
          return([units, minimum, maximum])
        else
          return(nil)
        end
      else
        return(nil)
      end
    end
    
   
  end

  
end
