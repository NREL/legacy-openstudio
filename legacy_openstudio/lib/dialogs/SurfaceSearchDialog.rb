# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/dialogs/Dialogs")
require("legacy_openstudio/lib/dialogs/LastReportInterface")

module LegacyOpenStudio

  class SurfaceSearchDialog < PropertiesDialog

    def initialize(container, interface, hash)
      super
      @container = WindowContainer.new("Surface Search", 550, 400, 150, 150)
      @container.set_file(Plugin.dir + "/lib/dialogs/html/SurfaceSearch.html")
      
      @hash['CLASS'] = ""
      @hash['NAME'] = ""
      @hash['TYPE'] = ""
      @hash['CONSTRUCTION'] = ""
      @hash['OUTSIDE_BOUNDARY_CONDITION'] = ""
      @hash['SUN'] = ""
      @hash['WIND'] = ""
      @hash['SHADING_CONTROL_NAME'] = ""
      @hash['FRAME_AND_DIVIDER_NAME'] = ""
      @hash['SCENE_NAME'] = ""
      
      @last_report = ""
      
      # do profiling
      @profile = false

      add_callbacks
    end


    def add_callbacks
      super
      @container.web_dialog.add_action_callback("on_change_class") { on_change_class }
      @container.web_dialog.add_action_callback("on_search_model") { on_search_model }
      @container.web_dialog.add_action_callback("on_search_selection") { on_search_selection }
      @container.web_dialog.add_action_callback("on_unhide_all") { on_unhide_all }
      @container.web_dialog.add_action_callback("on_save_scene") { on_save_scene }
      @container.web_dialog.add_action_callback("on_last_report") { on_last_report }
      @container.web_dialog.add_action_callback("on_cancel") { on_cancel }
    end
    
    def on_load
      super
      set_select_options("CLASS", ["", "BuildingSurface:Detailed", "FenestrationSurface:Detailed", "Shading:Site:Detailed", "Shading:Building:Detailed", "Shading:Zone:Detailed"])
      on_change_class
    end 
    
    def on_change_element(d, p)
      super
    end

    def on_change_class

      case (@hash['CLASS'])

      when ""
      
        enable_element("CLASS")
        enable_element("NAME")
        enable_element("CONSTRUCTION")
        
        @hash['TYPE'] = ""
        disable_element("TYPE")
        @hash['OUTSIDE_BOUNDARY_CONDITION'] = ""
        disable_element("OUTSIDE_BOUNDARY_CONDITION")
        @hash['SUN'] = ""
        disable_element("SUN")
        @hash['WIND'] = ""
        disable_element("WIND")
        @hash['SHADING_CONTROL_NAME'] = ""
        disable_element("SHADING_CONTROL_NAME")
        @hash['FRAME_AND_DIVIDER_NAME'] = ""
        disable_element("FRAME_AND_DIVIDER_NAME")
        
        object_names = Plugin.model_manager.construction_manager.constructions.collect { |object| object.name }
        object_names = [""].concat(object_names.sort)
        set_select_options("CONSTRUCTION", object_names)
      
      when "BuildingSurface:Detailed"

        enable_element("CLASS")
        enable_element("NAME")
        enable_element("TYPE")
        enable_element("CONSTRUCTION")
        enable_element("OUTSIDE_BOUNDARY_CONDITION")
        enable_element("SUN")
        enable_element("WIND")
        
        @hash['SHADING_CONTROL_NAME'] = ""
        disable_element("SHADING_CONTROL_NAME")
        @hash['FRAME_AND_DIVIDER_NAME'] = ""
        disable_element("FRAME_AND_DIVIDER_NAME")
                
        set_select_options("TYPE", ["", "Floor", "Wall", "Ceiling", "Roof"])
        
        object_names = Plugin.model_manager.construction_manager.constructions.collect { |object| object.name }
        object_names = [""].concat(object_names.sort)
        set_select_options("CONSTRUCTION", object_names)
        set_select_options("OUTSIDE_BOUNDARY_CONDITION", ["", "Surface", "Adiabatic", "Zone", "Outdoors", "Ground", "GroundFCfactorMethod", 
                                                                                  "GroundSlabPreprocessorAverage", "GroundSlabPreprocessorCore", "GroundSlabPreprocessorPerimeter", 
                                                                                  "GroundBasementPreprocessorAverageWall", "GroundBasementPreprocessorAverageFloor", 
                                                                                  "GroundBasementPreprocessorUpperWall", "GroundBasementPreprocessorLowerWall",
                                                                                  "OtherSideCoefficients", "OtherSideConditionsModel"])
        set_select_options("SUN", ["", "SunExposed", "NoSun"])
        set_select_options("WIND", ["", "WindExposed", "NoWind"])
        set_select_options("SHADING_CONTROL_NAME", [""])
        set_select_options("FRAME_AND_DIVIDER_NAME", [""])

        update

      when "FenestrationSurface:Detailed"

        enable_element("CLASS")
        enable_element("NAME")
        enable_element("TYPE")
        enable_element("CONSTRUCTION")
        enable_element("SHADING_CONTROL_NAME")
        enable_element("FRAME_AND_DIVIDER_NAME")
        
        @hash['OUTSIDE_BOUNDARY_CONDITION'] = ""
        disable_element("OUTSIDE_BOUNDARY_CONDITION")
        @hash['SUN'] = ""
        disable_element("SUN")
        @hash['WIND'] = ""
        disable_element("WIND")
        
        set_select_options("TYPE", ["", "Window", "Door", "Glass Door", "Tubular Daylight Dome", "Tubular Daylight Diffuser"])
        
        object_names = Plugin.model_manager.construction_manager.constructions.collect { |object| object.name }
        object_names = [""].concat(object_names.sort)
        set_select_options("CONSTRUCTION", object_names)
        
        set_select_options("OUTSIDE_BOUNDARY_CONDITION", [""])
        set_select_options("SUN", [""])
        set_select_options("WIND", [""])

        object_names = Plugin.model_manager.input_file.find_objects_by_class_name("WindowProperty:ShadingControl").collect { |object| object.name }
        object_names = [""].concat(object_names.sort)
        set_select_options("SHADING_CONTROL_NAME", object_names)

        object_names = Plugin.model_manager.input_file.find_objects_by_class_name("WindowProperty:FrameAndDivider").collect { |object| object.name }
        object_names = [""].concat(object_names.sort)
        set_select_options("FRAME_AND_DIVIDER_NAME", object_names)
        
        update
        
      when "Shading:Site:Detailed", "Shading:Building:Detailed", "Shading:Zone:Detailed"
      
        enable_element("CLASS")
        enable_element("NAME")

        @hash['TYPE'] = ""
        disable_element("TYPE")
        @hash['CONSTRUCTION'] = ""
        disable_element("CONSTRUCTION")
        @hash['OUTSIDE_BOUNDARY_CONDITION'] = ""
        disable_element("OUTSIDE_BOUNDARY_CONDITION")
        @hash['SUN'] = ""
        disable_element("SUN")
        @hash['WIND'] = ""
        disable_element("WIND")
        @hash['SHADING_CONTROL_NAME'] = ""
        disable_element("SHADING_CONTROL_NAME")
        @hash['FRAME_AND_DIVIDER_NAME'] = ""
        disable_element("FRAME_AND_DIVIDER_NAME")
        
        set_select_options("TYPE", [""])
        set_select_options("CONSTRUCTION", [""])
        set_select_options("OUTSIDE_BOUNDARY_CONDITION", [""])
        set_select_options("SUN", [""])
        set_select_options("WIND", [""])
        set_select_options("SHADING_CONTROL_NAME", [""])
        set_select_options("FRAME_AND_DIVIDER_NAME", [""])

        update

      end
      
    end
    
    def on_search_model
    
      # this was not stopping object info window from flickering
      #result = Sketchup.active_model.selection.remove_observer(Plugin.model_manager.selection_observer)

      model = Sketchup.active_model
      model.selection.clear
      model.entities.each {|e| model.selection.add(e)}
      selected_entities = search(model.selection)   
      model.selection.clear
      model.selection.add(selected_entities)

      #Sketchup.active_model.selection.add_observer(Plugin.model_manager.selection_observer)
    end
    
    def on_search_selection
      model = Sketchup.active_model
      search(model.selection)
    end
    
    def search(selection)
    
      if selection.empty?
        UI.messagebox("Selection is empty, please select objects for searching or choose 'Search in Entire Model'.")
        return []
      end
      
      @last_report = "Search results:\n"
      
      selected_entities = []
      
      model = Sketchup.active_model
      model.start_operation("Surface Search", true)
      
      begin
      
        if @profile
          require 'legacy_openstudio/stdruby/profiler'
          Profiler__::start_profile
        end
        
        progress_dialog = ProgressDialog.new

        # hide all zones, surfaces, sub surfaces, and shading surfaces, and edges
        Plugin.model_manager.zones.each { |zone| zone.entity.hidden = true }
        Plugin.model_manager.base_surfaces.each do |base_surface| 
          base_surface.entity.hidden = true 
          base_surface.entity.edges.each { |edge| edge.hidden = true }
        end
        Plugin.model_manager.sub_surfaces.each do |sub_surface| 
          sub_surface.entity.hidden = true 
          sub_surface.entity.edges.each { |edge| edge.hidden = true }
        end
        Plugin.model_manager.shading_surfaces.each do |shading_surface| 
          shading_surface.entity.hidden = true 
          shading_surface.entity.edges.each { |edge| edge.hidden = true }
        end

        name = @hash["NAME"].upcase
        type = @hash["TYPE"].upcase
        construction = @hash["CONSTRUCTION"].upcase
        outside_boundary_condition = @hash["OUTSIDE_BOUNDARY_CONDITION"].upcase
        sun = @hash["SUN"].upcase
        wind = @hash["WIND"].upcase
        shading_control = @hash['SHADING_CONTROL_NAME'].upcase
        frame_and_divider = @hash['FRAME_AND_DIVIDER_NAME'].upcase

        # select on surface type
        if (@hash['CLASS'] == "" or @hash['CLASS'] == "BuildingSurface:Detailed")

          num_base_surfaces = Plugin.model_manager.base_surfaces.length
          Plugin.model_manager.base_surfaces.each_index do |index|

            progress_dialog.update_progress(100*index.to_f/num_base_surfaces.to_f, "Searching Surfaces")

            input_object = Plugin.model_manager.base_surfaces[index].input_object

            if Plugin.model_manager.base_surfaces[index].in_selection?(selection) and
              input_object.fields[1].to_s.upcase.include?(name) and
              input_object.fields[2].to_s.upcase.include?(type) and
              input_object.fields[3].to_s.upcase.include?(construction) and
              input_object.fields[5].to_s.upcase.include?(outside_boundary_condition) and
              input_object.fields[7].to_s.upcase.include?(sun) and
              input_object.fields[8].to_s.upcase.include?(wind) and
              shading_control.empty? and frame_and_divider.empty?

               # unhide face
               Plugin.model_manager.base_surfaces[index].entity.visible = true    
               selected_entities << Plugin.model_manager.base_surfaces[index].entity

               # unhide edges
               Plugin.model_manager.base_surfaces[index].entity.edges.each {|edge| edge.visible = true }

               # unhide zone
               Plugin.model_manager.base_surfaces[index].parent.entity.visible = true      
               
               # add to report
               @last_report << "#{input_object.class_name}, #{input_object.fields[1].to_s}\n"

            end
          end
        end

        if (@hash['CLASS'] == "" or @hash['CLASS'] == "FenestrationSurface:Detailed")

          num_sub_surfaces = Plugin.model_manager.sub_surfaces.length
          Plugin.model_manager.sub_surfaces.each_index do |index|

            progress_dialog.update_progress(100*index.to_f/num_sub_surfaces.to_f, "Searching SubSurfaces")

            input_object = Plugin.model_manager.sub_surfaces[index].input_object

            if Plugin.model_manager.sub_surfaces[index].in_selection?(selection) and
              input_object.fields[1].to_s.upcase.include?(name) and
              input_object.fields[2].to_s.upcase.include?(type) and
              input_object.fields[3].to_s.upcase.include?(construction) and
              outside_boundary_condition.empty? and sun.empty? and wind.empty?
              input_object.fields[7].to_s.upcase.include?(shading_control)
              input_object.fields[8].to_s.upcase.include?(frame_and_divider)

               # unhide face
               Plugin.model_manager.sub_surfaces[index].entity.visible = true  
               selected_entities << Plugin.model_manager.sub_surfaces[index].entity

               # unhide edges
               Plugin.model_manager.sub_surfaces[index].entity.edges.each {|edge| edge.visible = true }

               # unhide base surface
               #Plugin.model_manager.sub_surfaces[index].parent.entity.visible = true   

               # unhide base surface edges
               Plugin.model_manager.sub_surfaces[index].parent.entity.edges.each {|edge| edge.visible = true }

               # unhide zone
               Plugin.model_manager.sub_surfaces[index].parent.parent.entity.visible = true   
               
               # add to report
               @last_report << "#{input_object.class_name}, #{input_object.fields[1].to_s}\n"
            end
          end
        end

        if (@hash['CLASS'] == "" or @hash['CLASS'] == "Shading:Zone:Detailed")

          idf_class = "SHADING:ZONE:DETAILED"

          num_shading_surfaces = Plugin.model_manager.shading_surfaces.length
          Plugin.model_manager.shading_surfaces.each_index do |index|

            progress_dialog.update_progress(100*index.to_f/num_shading_surfaces.to_f, "Searching Attached Shading Surfaces")

            input_object = Plugin.model_manager.shading_surfaces[index].input_object

            if Plugin.model_manager.shading_surfaces[index].in_selection?(selection) and
               input_object.fields[0].to_s.upcase.include?(idf_class) and
               input_object.fields[1].to_s.upcase.include?(name) and
               type.empty? and construction.empty? and
               outside_boundary_condition.empty? and sun.empty? and wind.empty? and
               shading_control.empty? and frame_and_divider.empty?

               # unhide face
               Plugin.model_manager.shading_surfaces[index].entity.visible = true 
               selected_entities << Plugin.model_manager.shading_surfaces[index].entity

               # unhide edges
               Plugin.model_manager.shading_surfaces[index].entity.edges.each {|edge| edge.visible = true }

               # unhide base surface
               #Plugin.model_manager.shading_surfaces[index].parent.entity.visible = true   

               # unhide base surface edges
               Plugin.model_manager.shading_surfaces[index].parent.entity.edges.each {|edge| edge.visible = true }

               # unhide zone
               Plugin.model_manager.shading_surfaces[index].parent.parent.entity.visible = true      
               
               # add to report
               @last_report << "#{input_object.class_name}, #{input_object.fields[1].to_s}\n"
            end
            
          end
        end

        if (@hash['CLASS'] == "" or @hash['CLASS'] == "Shading:Site:Detailed" or @hash['CLASS'] == "Shading:Building:Detailed")

          idf_class = ""
          case (@hash['CLASS'])
            when "Shading:Site:Detailed"
              idf_class = "SHADING:SITE:DETAILED"
            when "Shading:Building:Detailed"
              idf_class = "SHADING:BUILDING:DETAILED"
          end

          num_shading_surfaces = Plugin.model_manager.shading_surfaces.length
          Plugin.model_manager.shading_surfaces.each_index do |index|

            progress_dialog.update_progress(100*index.to_f/num_shading_surfaces.to_f, "Searching Detached Shading Surfaces")

            input_object = Plugin.model_manager.shading_surfaces[index].input_object
            
            if Plugin.model_manager.shading_surfaces[index].in_selection?(selection) and
               input_object.fields[0].to_s.upcase.include?(idf_class) and
               input_object.fields[1].to_s.upcase.include?(name) and
               type.empty? and construction.empty? and
               outside_boundary_condition.empty? and sun.empty? and wind.empty? and
               shading_control.empty? and frame_and_divider.empty?

               # unhide face
               Plugin.model_manager.shading_surfaces[index].entity.visible = true 
               selected_entities << Plugin.model_manager.shading_surfaces[index].entity

               # unhide edges
               Plugin.model_manager.shading_surfaces[index].entity.edges.each {|edge| edge.visible = true }

               # unhide zone
               Plugin.model_manager.shading_surfaces[index].parent.entity.visible = true     
               
               # add to report
               @last_report << "#{input_object.class_name}, #{input_object.fields[1].to_s}\n"
            end
           
          end        
        end      
      
        if @profile
          puts "Profiling results in #{Dir.pwd}"
          File.open(Dir.pwd + "/SurfaceSearchDialog.profile", 'w') do |file|
            Profiler__::stop_profile
            Profiler__::print_profile(file)
          end
        end

      ensure
        progress_dialog.destroy
      end

      model.commit_operation 
      
      return selected_entities

    end
    
    def on_unhide_all
      # unhide all
      model = Sketchup.active_model
      model.start_operation("Unhide All", true)
      
      Plugin.model_manager.zones.each { |zone| zone.entity.visible = true }
      Plugin.model_manager.all_surfaces.each do |surface| 
        surface.entity.visible = true 
        surface.entity.edges.each { |edge| edge.visible = true }
      end
        
      model.commit_operation
    end    

    def on_save_scene
    
      # this does not seem to remember which surfaces are hidden within each group (Zone)

      # 1 - Camera Location,
      # 2 - Drawing Style,
      # 4 - Shadow Settings,
      # 8 - Axes Location,
      # 16 - Hidden Geometry,
      # 32 - Visible Layers,
      # 64 - Active Section Planes.
      
      scene_name = @hash['SCENE_NAME']
      if not scene_name or scene_name.empty?
        UI.messagebox("Please enter a scene name.")
        return 
      end
      
      # see if page already exists
      model = Sketchup.active_model
      pages = model.pages
      if pages[scene_name]
        UI.messagebox("Please enter a unique scene name.")
        return 
      end
      
      # get current page, make a default one if no pages
      current_page = pages.selected_page
      if current_page.nil?
        current_page = pages.add("Default")
        current_page.use_axes = false
        current_page.use_camera = false
        current_page.use_hidden = false
        current_page.use_hidden_layers = false
        current_page.use_rendering_options = false
        current_page.use_section_planes = false
        current_page.use_shadow_info = false
        current_page.use_style = false
      end
      
      page = pages.add(scene_name)
      page.use_axes = false
      page.use_camera = false
      page.use_hidden = true
      page.use_hidden_layers = true
      page.use_rendering_options = false
      page.use_section_planes = false
      page.use_shadow_info = false
      page.use_style = false
      page.update(16)
      page.update(32)
      
      puts page.hidden_entities
      
      pages.selected_page = current_page
      
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
    
    def on_cancel
      close
    end
    
  end

end
