# OpenStudio
# Copyright (c) 2008-2010, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("OpenStudio/lib/dialogs/Dialogs")
require("OpenStudio/lib/interfaces/BaseSurface")
require("OpenStudio/lib/interfaces/SubSurface")
require("OpenStudio/lib/dialogs/LastReportInterface")

module OpenStudio

  class SurfaceMatchingDialog < PropertiesDialog

    def initialize(container, interface, hash)
      super
      @container = WindowContainer.new("Surface Matching", 380, 200, 150, 150)
      @container.set_file(Plugin.dir + "/lib/dialogs/html/SurfaceMatching.html")
      
      @last_report = ""
      
      # do profiling
      @profile = false
      
      add_callbacks
    end

    def add_callbacks
      super
      @container.web_dialog.add_action_callback("on_match_selected") { on_match_selected }
      @container.web_dialog.add_action_callback("on_match_all") { on_match_all }
      @container.web_dialog.add_action_callback("on_unmatch_selected") { on_unmatch_selected }
      @container.web_dialog.add_action_callback("on_unmatch_all") { on_unmatch_all }
      @container.web_dialog.add_action_callback("on_last_report") { on_last_report }
      @container.web_dialog.add_action_callback("on_cancel") { on_cancel }
    end
    
    def on_load
      super
    end     
    
    def on_match_selected
      model = Sketchup.active_model
      match(model.selection)
    end

    def on_match_all
      model = Sketchup.active_model
      model.selection.clear
      model.entities.each {|e| model.selection.add(e)}
      match(model.selection)    
      model.selection.clear
    end
    
    def on_unmatch_selected
      model = Sketchup.active_model
      unmatch(model.selection)
    end

    def on_unmatch_all
      model = Sketchup.active_model
      model.selection.clear
      model.entities.each {|e| model.selection.add(e)}
      unmatch(model.selection)    
      model.selection.clear
    end
    
    def match(selection)
    
      @last_report = "Surface Matching Report:\n"
      @last_report << "Action, BuildingSurface:Detailed #1, Zone #1, BuildingSurface:Detailed #2, Zone #2\n"
    
      if selection.empty?
        UI.messagebox("Selection is empty, please select objects for matching routine or choose 'Match in Entire Model'.")
        return 
      end
      
      result = UI.messagebox(
"Warning this will match surfaces and subsurfaces 
within and surrounding the selected Zones.\n
This operation cannot be undone.\n  
Do you want to continue?", MB_OKCANCEL)      

      if result == 2 # cancel
        return false
      end
  
      # get all base surfaces
      base_surfaces = Plugin.model_manager.base_surfaces
      begin
      
        if @profile
          require 'OpenStudio/stdruby/profiler'
          Profiler__::start_profile
        end

        # create a progress dialog
        progress_dialog = ProgressDialog.new
        progress_dialog.update_progress(0, "Matching Surfaces")

        # processed and total number of comparisons
        processed_num = 0
        total_num = (base_surfaces.length * (base_surfaces.length-1)) / 2

        # num matches found
        num_matches = 0

        # loop over all base surfaces
        base_surfaces.each_index do |i|
        
          # get the bounding box
          bounds = base_surfaces[i].entity.bounds
        
          # get the polygon, reverse it
          reverse_face_polygon = base_surfaces[i].face_polygon.reverse
          
          # get the normal
          face_normal = base_surfaces[i].entity.normal

          # don't process empty polygons
          next if reverse_face_polygon.empty?

          # loop over remaining surfaces
          (i+1..base_surfaces.length-1).each do |j|
         
            # update number of comparisons
            processed_num += 1
            percent_complete = 100*processed_num/total_num
            progress_dialog.update_progress(percent_complete, "Matching Base Surfaces")
            
            # selection must contain either surface
            next if not (selection.contains?(base_surfaces[i].entity) or selection.contains?(base_surfaces[i].parent.entity) or
                         selection.contains?(base_surfaces[j].entity) or selection.contains?(base_surfaces[j].parent.entity))
                         
            # check for intersection of bounding boxes
            next if not bounds.contains?(base_surfaces[j].entity.bounds)
            
            # check normal dot product
            next if not face_normal.dot(base_surfaces[j].entity.normal) < -0.98

            # check if the reverse of this polygon equals the other polygon
            if (reverse_face_polygon.circular_eql?(base_surfaces[j].face_polygon))

              @last_report << "Match, '#{base_surfaces[i].name}', '#{base_surfaces[i].input_object.fields[4]}', '#{base_surfaces[j].name}', '#{base_surfaces[j].input_object.fields[4]}' \n"

              base_surfaces[i].set_other_side_surface(base_surfaces[j])
              base_surfaces[j].set_other_side_surface(base_surfaces[i])

              Plugin.model_manager.input_file.modified = true
              break
            end
          end
        end

      ensure
        progress_dialog.destroy
      end
      
      @last_report << "\nSubSurface Matching Report:\n"
      @last_report << "Action, FenestrationSurface:Detailed #1, BuildingSurface:Detailed #1, FenestrationSurface:Detailed #2, BuildingSurface:Detailed #2\n"
      
      # get all sub surfaces
      sub_surfaces = Plugin.model_manager.sub_surfaces
      begin
      
        # create a progress dialog
        progress_dialog = ProgressDialog.new
        progress_dialog.update_progress(0, "Matching Sub-Surfaces")

        # processed and total number of comparisons
        processed_num = 0
        total_num = (sub_surfaces.length * (sub_surfaces.length-1)) / 2

        # loop over all sub surfaces
        sub_surfaces.each_index do |i|
        
          # get the bounding box
          bounds = sub_surfaces[i].entity.bounds
          
          # get the polygon, reverse it
          reverse_face_polygon = sub_surfaces[i].face_polygon.reverse
          
          # get the normal
          face_normal = sub_surfaces[i].entity.normal
          
          # don't process empty polygons
          next if reverse_face_polygon.empty?

          # loop over remaining surfaces
          (i+1..sub_surfaces.length-1).each do |j|

            # update number of comparisons
            processed_num += 1
            percent_complete = 100*processed_num/total_num
            progress_dialog.update_progress(percent_complete, "Matching Sub-Surfaces")
          
            # selection must contain either sub surface
            next if not (selection.contains?(sub_surfaces[i].entity) or selection.contains?(sub_surfaces[i].parent.entity) or selection.contains?(sub_surfaces[i].parent.parent.entity) or
                         selection.contains?(sub_surfaces[j].entity) or selection.contains?(sub_surfaces[j].parent.entity) or selection.contains?(sub_surfaces[j].parent.parent.entity))
           
            # check for intersection of bounding boxes
            next if not bounds.contains?(sub_surfaces[j].entity.bounds)
            
            # check normal dot product
            next if not face_normal.dot(sub_surfaces[j].entity.normal) < -0.98
            
            # check if this polygon equals the reverse of the other polygon
            if (reverse_face_polygon.circular_eql?(sub_surfaces[j].face_polygon))

              @last_report << "Match, '#{sub_surfaces[i].name}', '#{sub_surfaces[i].input_object.fields[4]}', '#{sub_surfaces[j].name}', '#{sub_surfaces[j].input_object.fields[4]}'\n"
              
              sub_surfaces[i].set_other_side_sub_surface(sub_surfaces[j])
              sub_surfaces[j].set_other_side_sub_surface(sub_surfaces[i])

              Plugin.model_manager.input_file.modified = true
              break
            end
          end
        end
        
        if @profile
          puts "Profiling results in #{Dir.pwd}"
          File.open(Dir.pwd + "/SurfaceMatchingDialog.profile", 'w') do |file|
            Profiler__::stop_profile
            Profiler__::print_profile(file)
          end
        end

      ensure
        progress_dialog.destroy
      end

    end 
    
    def unmatch(selection)
    
      @last_report = "Surface Unmatching Report:\n"
      @last_report << "Action, BuildingSurface:Detailed #1, Zone #1, BuildingSurface:Detailed #2, Zone #2\n"
      
      if selection.empty?
        UI.messagebox("Selection is empty, please select objects for unmatching routine or choose 'Unmatch in Entire Model'.")
        return 
      end
      
      result = UI.messagebox(
"Warning this will unmatch surfaces and subsurfaces 
within and surrounding the selected Zones.\n
This operation cannot be undone.\n  
Do you want to continue?", MB_OKCANCEL)

      if result == 2 # cancel
        return false
      end
  
      Plugin.model_manager.base_surfaces.each do |base_surface|
        if selection.contains?(base_surface.entity) or selection.contains?(base_surface.parent.entity)
          if base_surface.input_object.fields[5].to_s.upcase == "SURFACE"
          
            # try to get the other side surface
            other_zone = ""
            other_name = base_surface.input_object.fields[6].to_s
            other_name_upcase = other_name.upcase
            other_surfaces = Plugin.model_manager.base_surfaces.collect { |other| other if other.name.upcase == other_name_upcase }
            
            base_surface.unset_other_side_surface
            
            if other_surfaces.empty?
              other_zone = "Not Found"
              other_name = other_name + " - Surface Not Found"
            else
              other_zone = other_surfaces[0].input_object.fields[4]
              other_surfaces[0].unset_other_side_surface
            end
            
            @last_report << "Unmatch, '#{base_surface.name}', '#{base_surface.input_object.fields[4]}', '#{other_name}', '#{other_zone}'\n"   
          end
        end
      end

      @last_report << "\nSubSurface Unmatching Report:\n"
      @last_report << "Action, FenestrationSurface:Detailed #1, BuildingSurface:Detailed #1, FenestrationSurface:Detailed #2, BuildingSurface:Detailed #2\n"
      
      Plugin.model_manager.sub_surfaces.each do |sub_surface|
        if selection.contains?(sub_surface.entity) or selection.contains?(sub_surface.parent.entity) or selection.contains?(sub_surface.parent.parent.entity)
          if not sub_surface.input_object.fields[5].to_s.empty?
          
            # try to get the other side surface
            other_base_surface = ""
            other_name = sub_surface.input_object.fields[5].to_s
            other_name_upcase = other_name.upcase
            other_sub_surfaces = Plugin.model_manager.sub_surfaces.collect { |other| other if other.name.upcase == other_name_upcase }
            
            sub_surface.unset_other_side_sub_surface
            
            if other_sub_surfaces.empty?
              other_base_surface = "Not Found"
              other_name = other_name + " - SubSurface Not Found"
            else
              other_base_surface = other_sub_surfaces[0].input_object.fields[4]
              other_sub_surfaces[0].unset_other_side_sub_surface
            end
            
            @last_report << "Unmatch, '#{sub_surface.name}', '#{sub_surface.input_object.fields[4]}', '#{other_name}', '#{other_base_surface}'\n"
                     
          end
        end
      end     
      
      Plugin.model_manager.input_file.modified = true

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
