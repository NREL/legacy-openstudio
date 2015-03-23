# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/dialogs/FileInfoInterface")
require("legacy_openstudio/lib/dialogs/SimulationInfoInterface")
require("legacy_openstudio/lib/dialogs/ObjectInfoInterface")
require("legacy_openstudio/lib/dialogs/RunSimulationInterface")
require("legacy_openstudio/lib/dialogs/RenderingSettingsInterface")
require("legacy_openstudio/lib/dialogs/ColorScaleInterface")
require("legacy_openstudio/lib/dialogs/AnimationSettingsInterface")
require("legacy_openstudio/lib/dialogs/PreferencesInterface")
require("legacy_openstudio/lib/dialogs/AboutInterface")
require("legacy_openstudio/lib/dialogs/SurfaceSearchInterface")
require("legacy_openstudio/lib/dialogs/SurfaceMatchingInterface")
require("legacy_openstudio/lib/dialogs/DefaultConstructionsInterface")
require("legacy_openstudio/lib/dialogs/ZoneLoadsInterface")
require("legacy_openstudio/lib/dialogs/ThermostatInterface")
require("legacy_openstudio/lib/tools/DataTool")
require("legacy_openstudio/lib/tools/InfoTool")
require("legacy_openstudio/lib/tools/NewShadingTool")
require("legacy_openstudio/lib/tools/NewDaylightingControlsTool")
require("legacy_openstudio/lib/tools/NewOutputIlluminanceMapTool")
require("legacy_openstudio/lib/tools/NewZoneTool")
require("legacy_openstudio/lib//observers/ErrorObserver")  # This is hopefully only a temporary location


module LegacyOpenStudio

  class MenuManager

    attr_accessor :new_cmd, :open_cmd, :merge_cmd, :close_cmd, :save_cmd, :save_as_cmd, :revert_cmd
    attr_accessor :show_errors_cmd, :file_info_cmd, :sim_info_cmd, :object_info_cmd
    attr_accessor :zone_origin_cmd, :new_zone_cmd, :new_shading_cmd
    attr_accessor :new_daylighting_cmd, :new_illuminance_cmd
    attr_accessor :surface_matching_cmd, :surface_search_cmd, :zone_loads_cmd, :edit_thermostats_cmd
    attr_accessor :run_cmd, :proto_wiz_cmd, :comp_wiz_cmd, :info_tool_cmd
    attr_accessor :surf_mode_cmd, :data_mode_cmd, :data_settings_cmd, :color_scale_cmd, :data_tool_cmd
    attr_accessor :display_color_by_layer_cmd, :render_mode_5_cmd, :set_mode_only_cmd, :boundary_mode_cmd
    attr_accessor :anim_settings_cmd, :rwd_to_start_cmd, :rwd_anim_cmd, :play_anim_cmd, :fwd_anim_cmd, :fwd_to_end_cmd
    attr_accessor :prefs_cmd, :help_cmd, :about_cmd
    attr_accessor :test_cmd  # for testing only

    attr_accessor :plugin_menu, :rendering_menu, :animation_menu, :help_menu
    attr_accessor :command_toolbar, :rendering_toolbar, :animation_toolbar


    def initialize
      create_tools
      create_commands
      create_menus
      create_toolbars
      create_context_menu
    end


    def create_tools
      @new_zone_tool = NewZoneTool.new
      @new_shading_tool = NewShadingTool.new
      @new_daylighting_tool = NewDaylightingControlsTool.new
      @new_illuminance_tool = NewOutputIlluminanceMapTool.new
      @info_tool = InfoTool.new
      @data_tool = DataTool.new
    end


    def create_commands

      # Create all the commands (They must still be added to menus and toolbars next)
      @new_cmd = UI::Command.new("New") { Plugin.command_manager.new_input_file }
      @new_cmd.small_icon = Plugin.dir + "/lib/resources/icons/NewFile-16.png"
      @new_cmd.large_icon = Plugin.dir + "/lib/resources/icons/NewFile-24.png"
      @new_cmd.tooltip = "New EnergyPlus Input File"
      @new_cmd.status_bar_text = "New EnergyPlus Input File"
      @new_cmd.set_validation_proc {
        # kludge to run error checking for ruby script errors in the plugin
        detect_errors
        MF_ENABLED }


      @open_cmd = UI::Command.new("Open...") { Plugin.command_manager.open_input_file }
      @open_cmd.small_icon = Plugin.dir + "/lib/resources/icons/OpenFile-16.png"
      @open_cmd.large_icon = Plugin.dir + "/lib/resources/icons/OpenFile-24.png"
      @open_cmd.tooltip = "Open EnergyPlus Input File"
      @open_cmd.status_bar_text = "Open a new EnergyPlus input file"
      @open_cmd.set_validation_proc { MF_ENABLED }


      @merge_cmd = UI::Command.new("Merge...") { Plugin.command_manager.merge_input_file }
      @merge_cmd.set_validation_proc { MF_ENABLED }


      @close_cmd = UI::Command.new("Close") { Plugin.command_manager.close_input_file }
      @close_cmd.set_validation_proc { validate_input_file_association }


      @save_cmd = UI::Command.new("Save") { Plugin.command_manager.save_input_file }
      @save_cmd.small_icon = Plugin.dir + "/lib/resources/icons/SaveFile-16.png"
      @save_cmd.large_icon = Plugin.dir + "/lib/resources/icons/SaveFile-24.png"
      @save_cmd.tooltip = "Save EnergyPlus Input File"
      @save_cmd.status_bar_text = "Save the EnergyPlus input file"
      @save_cmd.set_validation_proc { MF_ENABLED }


      @save_as_cmd = UI::Command.new("Save As...") { Plugin.command_manager.save_input_file_as }
      @save_as_cmd.small_icon = Plugin.dir + "/lib/resources/icons/SaveFileAs-16.png"
      @save_as_cmd.large_icon = Plugin.dir + "/lib/resources/icons/SaveFileAs-24.png"
      @save_as_cmd.tooltip = "SaveAs EnergyPlus Input File"
      @save_as_cmd.status_bar_text = "Save the EnergyPlus input as a new file"
      @save_as_cmd.set_validation_proc { MF_ENABLED }


      @revert_cmd = UI::Command.new("Revert") { Plugin.command_manager.revert_input_file }
      @revert_cmd.set_validation_proc { validate_input_file_modified }


      @show_errors_cmd = UI::Command.new("Show Errors And Warnings") { Plugin.model_manager.show_errors }
      @show_errors_cmd.small_icon = Plugin.dir + "/lib/resources/icons/Warning-16.png"
      @show_errors_cmd.large_icon = Plugin.dir + "/lib/resources/icons/Warning-24.png"
      @show_errors_cmd.tooltip = "Show Errors And Warnings"
      @show_errors_cmd.status_bar_text = "Show errors and warnings window"
      @show_errors_cmd.set_validation_proc { MF_ENABLED }


      @file_info_cmd = UI::Command.new("File Info") { Plugin.dialog_manager.show(FileInfoInterface) }
      @file_info_cmd.set_validation_proc { Plugin.dialog_manager.validate(FileInfoInterface) if (Plugin.dialog_manager) }


      @sim_info_cmd = UI::Command.new("Simulation Info") { Plugin.dialog_manager.show(SimulationInfoInterface)  }
      @sim_info_cmd.set_validation_proc { Plugin.dialog_manager.validate(SimulationInfoInterface) if (Plugin.dialog_manager) }


      @object_info_cmd = UI::Command.new("Object Info") { Plugin.dialog_manager.show(ObjectInfoInterface) }
      @object_info_cmd.small_icon = Plugin.dir + "/lib/resources/icons/ObjectInfo-16.png"
      @object_info_cmd.large_icon = Plugin.dir + "/lib/resources/icons/ObjectInfo-24.png"
      @object_info_cmd.tooltip = "Show Object Info Window"
      @object_info_cmd.status_bar_text = "Show info about the selected EnergyPlus zone or surface"
      @object_info_cmd.set_validation_proc { Plugin.dialog_manager.validate(ObjectInfoInterface) if (Plugin.dialog_manager) }


      @surface_search_cmd = UI::Command.new("Surface Search") { Plugin.dialog_manager.show(SurfaceSearchInterface) }
      @surface_search_cmd.small_icon = Plugin.dir + "/lib/resources/icons/SurfaceSearch-16.png"
      @surface_search_cmd.large_icon = Plugin.dir + "/lib/resources/icons/SurfaceSearch-24.png"
      @surface_search_cmd.tooltip = "Search Surfaces"
      @surface_search_cmd.status_bar_text = "Search Surfaces"
      @surface_search_cmd.set_validation_proc { Plugin.dialog_manager.validate(SurfaceSearchInterface) if (Plugin.dialog_manager) } 
      
      
      @outliner_cmd = UI::Command.new("Outliner") { UI.show_inspector("Outliner") }
      @outliner_cmd.small_icon = Plugin.dir + "/lib/resources/icons/Outliner-16.png"
      @outliner_cmd.large_icon = Plugin.dir + "/lib/resources/icons/Outliner-24.png"
      @outliner_cmd.tooltip = "Show Outliner Window"
      @outliner_cmd.status_bar_text = "Show hierarchical outline of all SketchUp groups and components"
      @outliner_cmd.set_validation_proc { MF_ENABLED }  # No obvious way to check if already open or not


      # Choose Zone Origin  ....  Set Zone Origin  
      #@zone_origin_cmd = UI::Command.new("Set Zone Origin") { Sketchup.active_model.tools.push_tool(OriginTool.new) }


# "Add Zone" better?
      @new_zone_cmd = UI::Command.new("New Zone Tool") { Sketchup.active_model.select_tool(@new_zone_tool) }
      #@new_zone_cmd = UI::Command.new("New Zone") { Sketchup.active_model.tools.push_tool(NewZoneTool.new) }
      # Maybe don't want to push in this case because it should always finish with the Selection Tool so the user can immediately double-click the new zone origin.
      # On the other hand, it's nice to be able to hit Esc and go back to the previous tool.
      @new_zone_cmd.small_icon = Plugin.dir + "/lib/resources/icons/NewZone-16.png"
      @new_zone_cmd.large_icon = Plugin.dir + "/lib/resources/icons/NewZone-24.png"
      @new_zone_cmd.tooltip = "New EnergyPlus Zone"
      @new_zone_cmd.status_bar_text = "Create a new empty EnergyPlus zone"
      #@new_zone_cmd.set_validation_proc { MF_ENABLED }
      # Need validation to make sure not inside of another group


      @new_shading_cmd = UI::Command.new("New Shading Group Tool") { Sketchup.active_model.select_tool(@new_shading_tool)  }
      @new_shading_cmd.small_icon = Plugin.dir + "/lib/resources/icons/NewShading-16.png"
      @new_shading_cmd.large_icon = Plugin.dir + "/lib/resources/icons/NewShading-24.png"
      @new_shading_cmd.tooltip = "New EnergyPlus Shading Group"
      @new_shading_cmd.status_bar_text = "Create a new empty EnergyPlus shading group"
      #@new_shading_cmd.set_validation_proc { MF_ENABLED }
      # Need validation to make sure not inside of another group

      @new_daylighting_cmd = UI::Command.new("New Daylighting Control Tool") { Sketchup.active_model.select_tool(@new_daylighting_tool)  }
      @new_daylighting_cmd.small_icon = Plugin.dir + "/lib/resources/icons/NewDaylighting-16.png"
      @new_daylighting_cmd.large_icon = Plugin.dir + "/lib/resources/icons/NewDaylighting-24.png"
      @new_daylighting_cmd.tooltip = "New EnergyPlus Daylighting Control"
      @new_daylighting_cmd.status_bar_text = "Create a new EnergyPlus daylighting control"

      @new_illuminance_cmd = UI::Command.new("New Illuminance Map Tool") { Sketchup.active_model.select_tool(@new_illuminance_tool)  }
      @new_illuminance_cmd.small_icon = Plugin.dir + "/lib/resources/icons/NewIlluminance-16.png"
      @new_illuminance_cmd.large_icon = Plugin.dir + "/lib/resources/icons/NewIlluminance-24.png"
      @new_illuminance_cmd.tooltip = "New EnergyPlus Illuminance Map"
      @new_illuminance_cmd.status_bar_text = "Create a new EnergyPlus illuminance map"

      @surface_matching_cmd = UI::Command.new("Surface Matching") { Plugin.dialog_manager.show(SurfaceMatchingInterface) }
      @surface_matching_cmd.small_icon = Plugin.dir + "/lib/resources/icons/SurfaceMatchingSelected-16.png"
      @surface_matching_cmd.large_icon = Plugin.dir + "/lib/resources/icons/SurfaceMatchingSelected-24.png"
      @surface_matching_cmd.tooltip = "Surface Matching"
      @surface_matching_cmd.status_bar_text = "Match surfaces of selected objects across Zones"
      @surface_matching_cmd.set_validation_proc { Plugin.dialog_manager.validate(SurfaceMatchingInterface) if (Plugin.dialog_manager) } 

      @set_default_constructions_cmd = UI::Command.new("Default Constructions") { Plugin.dialog_manager.show(DefaultConstructionsInterface) }
      @set_default_constructions_cmd.small_icon = Plugin.dir + "/lib/resources/icons/SetDefaultConstPrefs-16.png"
      @set_default_constructions_cmd.large_icon = Plugin.dir + "/lib/resources/icons/SetDefaultConstPrefs-24.png"
      @set_default_constructions_cmd.tooltip = "Default Constructions"
      @set_default_constructions_cmd.status_bar_text = "Change the default constructions used for new surfaces and surface matching"
      @set_default_constructions_cmd.set_validation_proc { Plugin.dialog_manager.validate(DefaultConstructionsInterface) if (Plugin.dialog_manager) } 
     
      @zone_loads_cmd = UI::Command.new("Zone Loads") { Plugin.dialog_manager.show(ZoneLoadsInterface) }
      @zone_loads_cmd.small_icon = Plugin.dir + "/lib/resources/icons/ZoneLoads-16.png"
      @zone_loads_cmd.large_icon = Plugin.dir + "/lib/resources/icons/ZoneLoads-24.png"
      @zone_loads_cmd.tooltip = "Zone Loads"
      @zone_loads_cmd.status_bar_text = "Add Zone Loads"
      @zone_loads_cmd.set_validation_proc { Plugin.dialog_manager.validate(ZoneLoadsInterface) if (Plugin.dialog_manager) } 

      @edit_thermostats_cmd = UI::Command.new("Edit Thermostats") { Plugin.dialog_manager.show(ThermostatInterface) }
      @edit_thermostats_cmd.set_validation_proc { Plugin.dialog_manager.validate(ThermostatInterface) if (Plugin.dialog_manager) } 

      @new_construct_cmd = UI::Command.new("New Construction Stub") { Plugin.model_manager.construction_manager.new_construction_stub }
      @new_construct_cmd.set_validation_proc { MF_ENABLED }
      
      @new_schedule_cmd = UI::Command.new("New Schedule Stub") { Plugin.model_manager.schedule_manager.new_schedule_stub }
      @new_schedule_cmd.set_validation_proc { MF_ENABLED }
      
      @run_cmd = UI::Command.new("Run Simulation...") { Plugin.dialog_manager.show(RunSimulationInterface) }
      @run_cmd.small_icon = Plugin.dir + "/lib/resources/icons/RunEnergyPlus-16.png"
      @run_cmd.large_icon = Plugin.dir + "/lib/resources/icons/RunEnergyPlus-24.png"
      @run_cmd.tooltip = "Run EnergyPlus Simulation"
      @run_cmd.status_bar_text = "Run an EnergyPlus simulation"
      @run_cmd.set_validation_proc { Plugin.dialog_manager.validate(RunSimulationInterface) if (Plugin.dialog_manager) }

      @eefg_cmd = UI::Command.new("Example File Generator...") { Plugin.command_manager.open_eefg }
      @eefg_cmd.small_icon = Plugin.dir + "/lib/resources/icons/EEFG-16.png"
      @eefg_cmd.large_icon = Plugin.dir + "/lib/resources/icons/EEFG-24.png"
      @eefg_cmd.tooltip = "Connect to the EnergyPlus Example File Generator"
      @eefg_cmd.status_bar_text = "Connect to the EnergyPlus Example File Generator on the web"
      #@eefg_cmd.set_validation_proc { }  # Check if on-line

  # Tools

      @info_tool_cmd = UI::Command.new("Info Tool") { Sketchup.active_model.tools.push_tool(@info_tool) }
      @info_tool_cmd.small_icon = Plugin.dir + "/lib/resources/icons/InfoTool-16.png"
      @info_tool_cmd.large_icon = Plugin.dir + "/lib/resources/icons/InfoTool-24.png"
      @info_tool_cmd.tooltip = "Info Tool"
      @info_tool_cmd.status_bar_text = "Show EnergyPlus object data"
      #@info_cmd.set_validation_proc { MF_ENABLED }   MF_GRAYED, MF_CHECKED, or MF_UNCHECKED  (MF_DISABLED?)
      # MF_CHECKED / MF_UNCHECKED shows menu items with a check or toolbar buttons depressed.


  # Render Style / View Mode

      @hide_rest_cmd = UI::Command.new("Hide Rest of Model") { 
        Sketchup.active_model.rendering_options["InactiveHidden"] = (not Sketchup.active_model.rendering_options["InactiveHidden"]) }
      @hide_rest_cmd.small_icon = Plugin.dir + "/lib/resources/icons/HideRest-16.png"
      @hide_rest_cmd.large_icon = Plugin.dir + "/lib/resources/icons/HideRest-24.png"
      @hide_rest_cmd.tooltip = "Hide Rest of Model"
      @hide_rest_cmd.status_bar_text = "Hide all inactive SketchUp groups and components"
      @hide_rest_cmd.set_validation_proc {
        if (Sketchup.active_model)  # Not sure if this is necessary
          if (Sketchup.active_model.rendering_options["InactiveHidden"])
            next(MF_CHECKED)
          else
            next(MF_UNCHECKED)
          end
        end
      }

      @hidden_geom_cmd = UI::Command.new("View Hidden Geometry") {
        Sketchup.active_model.rendering_options["DrawHidden"] = (not Sketchup.active_model.rendering_options["DrawHidden"]) }
      @hidden_geom_cmd.small_icon = Plugin.dir + "/lib/resources/icons/SU_ViewHidden-16.png"
      @hidden_geom_cmd.large_icon = Plugin.dir + "/lib/resources/icons/SU_ViewHidden-24.png"
      @hidden_geom_cmd.tooltip = "View Hidden Geometry"
      @hidden_geom_cmd.status_bar_text = "View/hide hidden geometry"
      @hidden_geom_cmd.set_validation_proc {
        if (Sketchup.active_model)  # Not sure if this is necessary
          if (Sketchup.active_model.rendering_options["DrawHidden"])
            next(MF_CHECKED)
          else
            next(MF_UNCHECKED)
          end
        end
      }

      @xray_cmd = UI::Command.new("X-ray Rendering") {
        Sketchup.active_model.rendering_options["ModelTransparency"] = (not Sketchup.active_model.rendering_options["ModelTransparency"]) }
      @xray_cmd.small_icon = Plugin.dir + "/lib/resources/icons/tbRenderTransparentSmall.png"
      @xray_cmd.large_icon = Plugin.dir + "/lib/resources/icons/tbRenderTransparentLarge.png"
      @xray_cmd.tooltip = "View Model in X-Ray Mode"
      @xray_cmd.status_bar_text = "Turn transparent x-ray mode on and off"
      @xray_cmd.set_validation_proc {
        if (Sketchup.active_model)  # Not sure if this is necessary
          if (Sketchup.active_model.rendering_options["ModelTransparency"])
            next(MF_CHECKED)
          else
            next(MF_UNCHECKED)
          end
        end
      }

      @surf_mode_cmd = UI::Command.new("By Surface Class") { Plugin.model_manager.set_mode(0) }
      @surf_mode_cmd.small_icon = Plugin.dir + "/lib/resources/icons/RenderByType-16x16.png"
      @surf_mode_cmd.large_icon = Plugin.dir + "/lib/resources/icons/RenderByType-24x24.png"
      @surf_mode_cmd.tooltip = "Render By Surface Class"
      @surf_mode_cmd.status_bar_text = "Render EnergyPlus objects by surface class"
      @surf_mode_cmd.set_validation_proc {
        if (Plugin.model_manager)
          if (Plugin.model_manager.rendering_mode == 0)
            next(MF_CHECKED)
          else
            next(MF_UNCHECKED)
          end
        end
      }


      @data_mode_cmd = UI::Command.new("By Data Value") { Plugin.model_manager.set_mode(1) }
      @data_mode_cmd.small_icon = Plugin.dir + "/lib/resources/icons/RenderByData-16x16.png"
      @data_mode_cmd.large_icon = Plugin.dir + "/lib/resources/icons/RenderByData-24x24.png"
      @data_mode_cmd.tooltip = "Render By Data Value"
      @data_mode_cmd.status_bar_text = "Render EnergyPlus objects by data value"
      @data_mode_cmd.set_validation_proc {
        if (Plugin.model_manager)
          if (Plugin.model_manager.rendering_mode == 1)
            next(MF_CHECKED)
          else
            next(MF_UNCHECKED)
          end
        end
      }

      @boundary_mode_cmd = UI::Command.new("By Boundary") { Plugin.model_manager.set_mode(2) }
      @boundary_mode_cmd.small_icon = Plugin.dir + "/lib/resources/icons/RenderByBoundary-16x16.png"
      @boundary_mode_cmd.large_icon = Plugin.dir + "/lib/resources/icons/RenderByBoundary-24x24.png"
      @boundary_mode_cmd.tooltip = "Render By Boundary Condition"
      @boundary_mode_cmd.status_bar_text = "Render EnergyPlus objects by boundary condition"
      @boundary_mode_cmd.set_validation_proc {
        if (Plugin.model_manager)
          if (Plugin.model_manager.rendering_mode == 2)
            next(MF_CHECKED)
          else
            next(MF_UNCHECKED)
          end
        end
      }

      @display_color_by_layer_cmd = UI::Command.new("By Layer")  { Plugin.model_manager.set_mode(3) }
      #@display_color_by_layer_cmd.small_icon = Plugin.dir + "/lib/resources/icons/DisplayColorByLayer-16x16.png"
      #@display_color_by_layer_cmd.large_icon = Plugin.dir + "/lib/resources/icons/DisplayColorByLayer-24x24.png"
      @display_color_by_layer_cmd.tooltip = "Render By Layer"
      @display_color_by_layer_cmd.status_bar_text = "Render SketchUp entities by layer"
      @display_color_by_layer_cmd.set_validation_proc {
        if (Plugin.model_manager)
          if (Plugin.model_manager.rendering_mode == 3)
            next(MF_CHECKED)
          else
            next(MF_UNCHECKED)
          end
        end
      }

      # this doesn't relate to OpenStudio "rendering_mode". RenderMode is a SketchUp term.
      @render_mode_5_cmd = UI::Command.new("By Surface Normal")  { Plugin.model_manager.set_mode(4) }
      #@render_mode_5_cmd.small_icon = Plugin.dir + "/lib/resources/icons/RenderMode5-16x16.png"
      #@render_mode_5_cmd.large_icon = Plugin.dir + "/lib/resources/icons/RenderMode5-24x24.png"
      @render_mode_5_cmd.tooltip = "Render By Face Normal"
      @render_mode_5_cmd.status_bar_text = "Render SketchUp entities by face normal"
      @render_mode_5_cmd.set_validation_proc {
        if (Plugin.model_manager)
          if (Plugin.model_manager.rendering_mode == 4)
            next(MF_CHECKED)
          else
            next(MF_UNCHECKED)
          end
        end
      }

      @data_settings_cmd = UI::Command.new("Settings...") { Plugin.dialog_manager.show(RenderingSettingsInterface) }
      @data_settings_cmd.small_icon = Plugin.dir + "/lib/resources/icons/RenderSettings-16x16.png"
      @data_settings_cmd.large_icon = Plugin.dir + "/lib/resources/icons/RenderSettings-24x24.png"
      @data_settings_cmd.tooltip = "Rendering Settings"
      @data_settings_cmd.status_bar_text = "Show rendering settings window"
      @data_settings_cmd.set_validation_proc { Plugin.dialog_manager.validate(RenderingSettingsInterface) if (Plugin.dialog_manager) }

      @color_scale_cmd = UI::Command.new("Color Scale") { Plugin.dialog_manager.show(ColorScaleInterface) }
      @color_scale_cmd.small_icon = Plugin.dir + "/lib/resources/icons/ColorScale-16x16.png"
      @color_scale_cmd.large_icon = Plugin.dir + "/lib/resources/icons/ColorScale-24x24.png"
      @color_scale_cmd.tooltip = "Color Scale"
      @color_scale_cmd.status_bar_text = "Show color scale window"
      @color_scale_cmd.set_validation_proc { Plugin.dialog_manager.validate(ColorScaleInterface) if (Plugin.dialog_manager) }

      @data_tool_cmd = UI::Command.new("Data Tool") { Sketchup.active_model.tools.push_tool(@data_tool) }
      @data_tool_cmd.small_icon = Plugin.dir + "/lib/resources/icons/DataTool-16x16.png"
      @data_tool_cmd.large_icon = Plugin.dir + "/lib/resources/icons/DataTool-24x24.png"
      @data_tool_cmd.tooltip = "Data Tool"
      @data_tool_cmd.status_bar_text = "Data Tool"
      #@data_tool_cmd.set_validation_proc { MF_ENABLED }


  # Animation commands

      @anim_settings_cmd = UI::Command.new("Settings...") { Plugin.dialog_manager.show(AnimationSettingsInterface) }
      @anim_settings_cmd.small_icon = Plugin.dir + "/lib/resources/icons/AnimationSettings~16.png"
      @anim_settings_cmd.large_icon = Plugin.dir + "/lib/resources/icons/AnimationSettings~24.png"
      @anim_settings_cmd.tooltip = "Animation Settings"
      @anim_settings_cmd.status_bar_text = "Show animation settings"
      @anim_settings_cmd.set_validation_proc { Plugin.dialog_manager.validate(AnimationSettingsInterface) if (Plugin.dialog_manager) }

      @rwd_to_start_cmd = UI::Command.new("Reverse To Marker") { Plugin.animation_manager.reverse_to_marker }
      @rwd_to_start_cmd.small_icon = Plugin.dir + "/lib/resources/icons/RewindFull16.png"
      @rwd_to_start_cmd.large_icon = Plugin.dir + "/lib/resources/icons/RewindFull24.png"
      @rwd_to_start_cmd.tooltip = "Reverse To Marker"
      @rwd_to_start_cmd.status_bar_text = "Reverse animation to previous marker"

      @rwd_anim_cmd = UI::Command.new("Reverse") { Plugin.animation_manager.reverse }
      @rwd_anim_cmd.small_icon = Plugin.dir + "/lib/resources/icons/Rewind16.png"
      @rwd_anim_cmd.large_icon = Plugin.dir + "/lib/resources/icons/Rewind24.png"
      @rwd_anim_cmd.tooltip = "Reverse Frame"
      @rwd_anim_cmd.status_bar_text = "Reverse animation by one frame"
      @rwd_anim_cmd.set_validation_proc { Plugin.animation_manager.validate_reverse if (Plugin.animation_manager) }

      @play_anim_cmd = UI::Command.new("Play") { Plugin.animation_manager.play }
      @play_anim_cmd.small_icon = Plugin.dir + "/lib/resources/icons/Play16.png"
      @play_anim_cmd.large_icon = Plugin.dir + "/lib/resources/icons/Play24.png"
      @play_anim_cmd.tooltip = "Play"
      @play_anim_cmd.status_bar_text = "Play animation"
      @play_anim_cmd.set_validation_proc { Plugin.animation_manager.validate_play_animation if (Plugin.animation_manager) }

      @fwd_anim_cmd = UI::Command.new("Forward") { Plugin.animation_manager.forward }
      @fwd_anim_cmd.small_icon = Plugin.dir + "/lib/resources/icons/Forward16.png"
      @fwd_anim_cmd.large_icon = Plugin.dir + "/lib/resources/icons/Forward24.png"
      @fwd_anim_cmd.tooltip = "Forward Frame"
      @fwd_anim_cmd.status_bar_text = "Forward animation by one frame"
      @fwd_anim_cmd.set_validation_proc { Plugin.animation_manager.validate_forward if (Plugin.animation_manager) }

      @fwd_to_end_cmd = UI::Command.new("Forward To Marker") { Plugin.animation_manager.forward_to_marker }
      @fwd_to_end_cmd.small_icon = Plugin.dir + "/lib/resources/icons/ForwardFull16.png"
      @fwd_to_end_cmd.large_icon = Plugin.dir + "/lib/resources/icons/ForwardFull24.png"
      @fwd_to_end_cmd.tooltip = "Forward To Marker"
      @fwd_to_end_cmd.status_bar_text = "Forward animation to next marker"


  # Preferences
  
      @prefs_cmd = UI::Command.new("Preferences") { Plugin.dialog_manager.show(PreferencesInterface) }
      @prefs_cmd.set_validation_proc { MF_ENABLED }



  # Help / About

      @help_cmd = UI::Command.new("OpenStudio User Guide") { UI.open_external_file(Plugin.dir + "/doc/help/index.html") }
      @help_cmd.small_icon = Plugin.dir + "/lib/resources/icons/Help-16.png"
      @help_cmd.large_icon = Plugin.dir + "/lib/resources/icons/Help-24.png"
      @help_cmd.tooltip = "Help"
      @help_cmd.status_bar_text = "View the OpenStudio User Guide help documentation"
      @help_cmd.set_validation_proc { MF_ENABLED }

      @update_cmd = UI::Command.new("Check For Update") { Plugin.update_manager.check_for_update }
      @update_cmd.set_validation_proc { MF_ENABLED }

      @about_cmd = UI::Command.new("About OpenStudio...") { Plugin.dialog_manager.show(AboutInterface) }
      @about_cmd.set_validation_proc { MF_ENABLED }
      
      # validation_procs to add:
      #  Close - can't close if nothing is open

      # All these commands are so directly linked to Commands file code...maybe this code should go in there?

    end



    def create_menus

      # Add the plugin menu

      @plugin_menu = UI.menu("Plugins").add_submenu(Plugin.name)

      @plugin_menu.add_item(@new_cmd)
      @plugin_menu.add_item(@open_cmd)
      #@plugin_menu.add_item(@merge_cmd)
      @plugin_menu.add_item(@close_cmd)
      @plugin_menu.add_separator
      @plugin_menu.add_item(@save_cmd)
      @plugin_menu.add_item(@save_as_cmd)
      #@plugin_menu.add_item(@revert_cmd)
      @plugin_menu.add_separator
      @plugin_menu.add_item(@show_errors_cmd)
      @plugin_menu.add_separator
      @plugin_menu.add_item(@file_info_cmd)
      @plugin_menu.add_item(@sim_info_cmd)
      @plugin_menu.add_item(@object_info_cmd)
      @plugin_menu.add_separator
      @plugin_menu.add_item(@run_cmd)
      @plugin_menu.add_item(@eefg_cmd)
      @plugin_menu.add_separator
      @plugin_menu.add_item(@new_zone_cmd)
      @plugin_menu.add_item(@new_shading_cmd)
      @plugin_menu.add_item(@zone_loads_cmd)
      @plugin_menu.add_item(@new_daylighting_cmd)
      @plugin_menu.add_item(@new_illuminance_cmd)
      @plugin_menu.add_separator
      @plugin_menu.add_item(@info_tool_cmd)
      @plugin_menu.add_item(@surface_search_cmd)
      @plugin_menu.add_item(@set_default_constructions_cmd)
      @plugin_menu.add_item(@surface_matching_cmd)
      @plugin_menu.add_item(@edit_thermostats_cmd)
      @plugin_menu.add_item(@new_construct_cmd)
      @plugin_menu.add_item(@new_schedule_cmd)
      @plugin_menu.add_separator
      @rendering_menu = @plugin_menu.add_submenu("Rendering")
      @animation_menu = @plugin_menu.add_submenu("Animation")
      @plugin_menu.add_separator
      @plugin_menu.add_item(@prefs_cmd)
      @plugin_menu.add_separator
      @plugin_menu.add_item(@help_cmd)

      if (Plugin.platform == Platform_Windows)
        @plugin_menu.add_item(@update_cmd)  # Update is broken on the Mac
      end

      @plugin_menu.add_item(@about_cmd)

      #@plugin_menu.add_item(@test_cmd)


      # Add the Rendering menu
      
      @rendering_menu.add_item(@hide_rest_cmd)
      @rendering_menu.add_item(@hidden_geom_cmd)
      @rendering_menu.add_item(@xray_cmd)
      @rendering_menu.add_separator
      @rendering_menu.add_item(@surf_mode_cmd)
      @rendering_menu.add_item(@data_mode_cmd)
      @rendering_menu.add_item(@boundary_mode_cmd)
      #@rendering_menu.add_item(@set_mode_only_cmd)
      @rendering_menu.add_item(@display_color_by_layer_cmd)
      @rendering_menu.add_item(@render_mode_5_cmd)
      @rendering_menu.add_separator
      @rendering_menu.add_item(@data_settings_cmd)
      @rendering_menu.add_item(@color_scale_cmd)
      @rendering_menu.add_item(@data_tool_cmd)

      # Add the Animation menu
      
      @animation_menu.add_item(@rwd_to_start_cmd)
      @animation_menu.add_item(@rwd_anim_cmd)
      @animation_menu.add_item(@play_anim_cmd)
      @animation_menu.add_item(@fwd_anim_cmd)
      @animation_menu.add_item(@fwd_to_end_cmd)
      @animation_menu.add_separator
      @animation_menu.add_item(@anim_settings_cmd)

      # Add the help menu
      @help_menu = UI.menu("Help")#.add_submenu(Plugin.name)

      @help_menu.add_item(@help_cmd)

    end
    
    
    def create_toolbars

      # Add the EnergyPlus command toolbar

      @command_toolbar = UI::Toolbar.new(Plugin.name)  # + " Commands")
      @command_toolbar.add_item(@new_cmd)
      @command_toolbar.add_item(@open_cmd)
      @command_toolbar.add_item(@save_cmd)
      @command_toolbar.add_item(@save_as_cmd)
      @command_toolbar.add_separator
      @command_toolbar.add_item(@show_errors_cmd)
      @command_toolbar.add_separator
      @command_toolbar.add_item(@new_zone_cmd)
      @command_toolbar.add_item(@new_shading_cmd)
      @command_toolbar.add_item(@zone_loads_cmd)
      @command_toolbar.add_item(@new_daylighting_cmd)
      @command_toolbar.add_item(@new_illuminance_cmd)
      @command_toolbar.add_separator
      @command_toolbar.add_item(@info_tool_cmd)
      @command_toolbar.add_item(@object_info_cmd)
      @command_toolbar.add_item(@outliner_cmd)
      @command_toolbar.add_item(@surface_search_cmd)
      @command_toolbar.add_separator
      @command_toolbar.add_item(@surface_matching_cmd)
      @command_toolbar.add_item(@set_default_constructions_cmd)
      @command_toolbar.add_separator
      @command_toolbar.add_item(@run_cmd)
      @command_toolbar.add_item(@eefg_cmd)
      @command_toolbar.add_separator
      @command_toolbar.add_item(@help_cmd)
      @command_toolbar.restore

      # Add the EnergyPlus Rendering toolbar
      
      @rendering_toolbar = UI::Toolbar.new(Plugin.name + " Rendering")
      @rendering_toolbar.add_item(@hide_rest_cmd)
      @rendering_toolbar.add_item(@hidden_geom_cmd)
      @rendering_toolbar.add_item(@xray_cmd)
      @rendering_toolbar.add_separator
      @rendering_toolbar.add_item(@surf_mode_cmd)
      @rendering_toolbar.add_item(@boundary_mode_cmd)
      @rendering_toolbar.add_item(@data_mode_cmd)
      @rendering_toolbar.add_separator
      @rendering_toolbar.add_item(@data_settings_cmd)
      @rendering_toolbar.add_item(@color_scale_cmd)
      @rendering_toolbar.add_item(@data_tool_cmd)
      #@rendering_toolbar.show


      # Add the EnergyPlus Animation toolbar

      #@animation_toolbar = UI::Toolbar.new(Plugin.name + " Animation")
      @rendering_toolbar.add_separator
      @rendering_toolbar.add_item(@anim_settings_cmd)
      @rendering_toolbar.add_item(@rwd_to_start_cmd)
      @rendering_toolbar.add_item(@rwd_anim_cmd)
      @rendering_toolbar.add_item(@play_anim_cmd)
      @rendering_toolbar.add_item(@fwd_anim_cmd)
      @rendering_toolbar.add_item(@fwd_to_end_cmd)
      @rendering_toolbar.restore

    end
    
    
    def create_context_menu
      # This method could be cleaned up a bit
    
      floor_type_cmd = UI::Command.new('Floor') { change_type_to('FLOOR') }
      floor_type_cmd.set_validation_proc { validate_type('FLOOR') }
      
      wall_type_cmd = UI::Command.new('Wall') { change_type_to('WALL') }
      wall_type_cmd.set_validation_proc { validate_type('WALL') }
      
      ceiling_type_cmd = UI::Command.new('Ceiling') { change_type_to('CEILING') }
      ceiling_type_cmd.set_validation_proc { validate_type('CEILING') }
      
      roof_type_cmd = UI::Command.new('Roof') { change_type_to('ROOF') }
      roof_type_cmd.set_validation_proc { validate_type('ROOF') }

      window_type_cmd = UI::Command.new('Window') { change_type_to('WINDOW') }
      window_type_cmd.set_validation_proc { validate_type('WINDOW') }
      
      door_type_cmd = UI::Command.new('Door') { change_type_to('DOOR') }
      door_type_cmd.set_validation_proc { validate_type('DOOR') }
      
      glassdoor_type_cmd = UI::Command.new('GlassDoor') { change_type_to('GLASSDOOR') }
      glassdoor_type_cmd.set_validation_proc { validate_type('GLASSDOOR') }
      
      tdd_dome_type_cmd = UI::Command.new('TubularDaylightDome') { change_type_to('TubularDaylightDome') }
      tdd_dome_type_cmd.set_validation_proc { validate_type('TubularDaylightDome') }
      
      tdd_diffuser_type_cmd = UI::Command.new('TubularDaylightDiffuser') { change_type_to('TDD:DIFFUSER') }
      tdd_diffuser_type_cmd.set_validation_proc { validate_type('TDD:DIFFUSER') }



      building_shading_type_cmd = UI::Command.new('Building Shading') { change_shading_type_to('Building Shading') }
      building_shading_type_cmd.set_validation_proc { validate_shading_type('Building Shading') }

      site_shading_type_cmd = UI::Command.new('Site Shading') { change_shading_type_to('Site Shading') }
      site_shading_type_cmd.set_validation_proc { validate_shading_type('Site Shading') }



      surface_class_cmd = UI::Command.new('BUILDINGSURFACE:DETAILED') { change_class_to('BUILDINGSURFACE:DETAILED') }
      surface_class_cmd.set_validation_proc { validate_class('BUILDINGSURFACE:DETAILED') }
      
      sub_surface_class_cmd = UI::Command.new('FENESTRATIONSURFACE:DETAILED') { change_class_to('FENESTRATIONSURFACE:DETAILED') }
      sub_surface_class_cmd.set_validation_proc { validate_class('FENESTRATIONSURFACE:DETAILED') }

      attached_shading_class_cmd = UI::Command.new('SHADING:ZONE:DETAILED') { change_class_to('SHADING:ZONE:DETAILED') }
      attached_shading_class_cmd.set_validation_proc { validate_class('SHADING:ZONE:DETAILED') }
      
      detached_building_class_cmd = UI::Command.new('SHADING:BUILDING:DETAILED') { change_class_to('SHADING:BUILDING:DETAILED') }
      detached_building_class_cmd.set_validation_proc { validate_class('SHADING:BUILDING:DETAILED') }
      
      detached_fixed_class_cmd = UI::Command.new('SHADING:SITE:DETAILED') { change_class_to('SHADING:SITE:DETAILED') }
      detached_fixed_class_cmd.set_validation_proc { validate_class('SHADING:SITE:DETAILED') }


      # Add the EnergyPlus context menu handler

      UI.add_context_menu_handler do |menu|

        if (drawing_interface = Plugin.model_manager.selected_drawing_interface)
          menu.add_separator
          plugin_menu = menu.add_submenu(Plugin.name)
          plugin_menu.add_item(object_info_cmd)
          plugin_menu.add_separator
          plugin_menu.add_item(new_zone_cmd)
          plugin_menu.add_item(new_shading_cmd)

          case (drawing_interface.class.to_s)
          when 'LegacyOpenStudio::BaseSurface'
            plugin_menu.add_separator
            type_menu = plugin_menu.add_submenu("Surface Type")
            type_menu.add_item(floor_type_cmd)
            type_menu.add_item(wall_type_cmd)
            type_menu.add_item(ceiling_type_cmd)
            type_menu.add_item(roof_type_cmd)
          when 'LegacyOpenStudio::SubSurface'
            plugin_menu.add_separator
            type_menu = plugin_menu.add_submenu("Surface Type")
            type_menu.add_item(window_type_cmd)
            type_menu.add_item(door_type_cmd)
            type_menu.add_item(glassdoor_type_cmd)
            type_menu.add_item(tdd_dome_type_cmd)
            type_menu.add_item(tdd_diffuser_type_cmd)
          when 'LegacyOpenStudio::Zone'
            #plugin_menu.add_separator
            # set origin tool
          when 'LegacyOpenStudio::DetachedShadingGroup'
            plugin_menu.add_separator
            type_menu = plugin_menu.add_submenu("Surface Type")
            type_menu.add_item(building_shading_type_cmd)
            type_menu.add_item(site_shading_type_cmd)
          end

          #class_menu = energyplus_menu.add_submenu("Surface Class")
          #class_menu.add_item(surface_class_cmd)
          #class_menu.add_item(sub_surface_class_cmd)
          #class_menu.add_item(attached_shading_class_cmd)
          #class_menu.add_separator
          #class_menu.add_item(detached_building_class_cmd)
          #class_menu.add_item(detached_fixed_class_cmd)

        end
      end

    end


    def change_type_to(new_type)
      drawing_interface = Plugin.model_manager.selected_drawing_interface
      drawing_interface.input_object.fields[2] = drawing_interface.input_object.class_definition.field_definitions[2].get_choice_key(new_type)
      drawing_interface.paint_entity
    end


    def validate_type(this_type)
      drawing_interface = Plugin.model_manager.selected_drawing_interface
      if (drawing_interface.input_object.fields[2].upcase == this_type.upcase)
        return(MF_CHECKED)
      else
        return(MF_UNCHECKED)
      end
    end


    def change_shading_type_to(new_type)
      drawing_interface = Plugin.model_manager.selected_drawing_interface
      if (new_type == 'Site Shading')
        drawing_interface.surface_type = 0  # Set to site shading
      else
        drawing_interface.surface_type = 1  # Set to building shading
      end
      drawing_interface.on_change_input_object
    end


    def validate_shading_type(this_type)
      drawing_interface = Plugin.model_manager.selected_drawing_interface
      if (drawing_interface.surface_type == 0 and this_type == 'Site Shading')
        return(MF_CHECKED)
      elsif (drawing_interface.surface_type == 1 and this_type == 'Building Shading')
        return(MF_CHECKED)
      else
        return(MF_UNCHECKED)
      end
    end


    # This is not implemented yet.
    def change_class_to(new_class)
      drawing_interface = Plugin.model_manager.selected_drawing_interface
      
      case (new_class)
      when 'SURFACE:HEATTRANSFER'

      when 'SURFACE:HEATTRANSFER:SUB'
      
      when 'SURFACE:SHADING:ATTACHED'
        # Problem here is that there is no base surface, unless its a window and that's an unlikely surface to be changing into shading
        
      when 'SURFACE:SHADING:DETACHED:BUILDING'
        # Problem here is that detached surfaces need to move outside the zone group, if its a regular HT
        # OK to convert between different types of shading.
      
      end

    end


    def validate_class(this_class)
      drawing_interface = Plugin.model_manager.selected_drawing_interface
      if (drawing_interface.input_object.is_class_name?(this_class))
        return(MF_CHECKED)
      else
        return(MF_UNCHECKED)
      end
    end


# some proc validations

    def validate_input_file_modified

      state = MF_GRAYED

      if (Plugin.model_manager)
        if (Plugin.model_manager.input_file)
          if (Plugin.model_manager.input_file.modified?)
            state = MF_ENABLED
          end
        end
      end

      return(state)
    end


    def validate_input_file_association
      if (Plugin.model_manager)
        if (Plugin.model_manager.input_file.path.nil?)
          state = MF_GRAYED
        else
          state = MF_ENABLED
        end
     end
      return(state)
    end


  end
  
end
