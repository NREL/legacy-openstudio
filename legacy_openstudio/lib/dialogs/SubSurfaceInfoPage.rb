# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/dialogs/Dialogs")


module LegacyOpenStudio

  class SubSurfaceInfoPage < Page

    def add_callbacks
      super
      @container.web_dialog.add_action_callback("on_change_element") { |d, p| on_change_element(d, p) }  # This one does need to overwrite
      @container.web_dialog.add_action_callback("on_change_type") { on_change_type }
      @container.web_dialog.add_action_callback("on_change_base_surface") { on_change_base_surface }
    end


    def on_load
      #super
            
      # Populate construction list
      object_names = Plugin.model_manager.construction_manager.constructions.collect { |object| object.name }
      if (not object_names.contains?(@hash['CONSTRUCTION']))
        object_names.add(@hash['CONSTRUCTION'])
      end
      set_select_options("CONSTRUCTION", object_names.sort)

      # Populate base surface list
      object_names = Plugin.model_manager.input_file.find_objects_by_class_name("BUILDINGSURFACE:DETAILED").collect { |object| object.name }
      if (not object_names.contains?(@hash['BASE_SURFACE']))
        object_names.add(@hash['BASE_SURFACE'])
      end
      set_select_options("BASE_SURFACE", object_names.sort)

      set_select_options("OUTSIDE_BOUNDARY_OBJECT", [""])

      # Populate window frame and divider list
      object_names = Plugin.model_manager.input_file.find_objects_by_class_name("WINDOWPROPERTY:FRAMEANDDIVIDER").collect { |object| object.name }
      if (not object_names.contains?(@hash['FRAME_DIVIDER']))
        object_names.add(@hash['FRAME_DIVIDER'])
      end
      set_select_options("FRAME_DIVIDER", object_names.sort)
      
      # Populate shading device list
      object_names = Plugin.model_manager.input_file.find_objects_by_class_name("WINDOWPROPERTY:SHADINGCONTROL").collect { |object| object.name }
      if (not object_names.contains?(@hash['SHADING_DEVICE']))
        object_names.add(@hash['SHADING_DEVICE'])
      end
      set_select_options("SHADING_DEVICE", object_names.sort)

      on_change_type

      on_change_base_surface

      #super
      
      # Don't set the background color because it causes the dialog to flash.
      #@container.execute_function("setBackgroundColor('" + default_dialog_color + "')")
      update_units
      update
    end


    def on_change_element(d, p)
      super
      report
    end


    def on_change_type
            
      case (@hash['TYPE'].upcase)

      when "WINDOW", "GLASSDOOR"
        enable_element("SHADING_DEVICE")
        enable_element("FRAME_DIVIDER")
        enable_element("MULTIPLIER")

      when "DOOR"
        disable_element("SHADING_DEVICE")
        disable_element("FRAME_DIVIDER")
        enable_element("MULTIPLIER")

      when "TDD:DOME", "TDD:DIFFUSER"
        disable_element("SHADING_DEVICE")
        disable_element("FRAME_DIVIDER")
        disable_element("MULTIPLIER")
      end

    end


    def on_change_base_surface
      base_surface = Plugin.model_manager.input_file.find_object_by_class_and_name("BUILDINGSURFACE:DETAILED", @hash['BASE_SURFACE'])
      if (base_surface)

        case (base_surface.fields[5].upcase)

        when "OUTDOORS"
          enable_element("VIEW_FACTOR_TO_GROUND")
          disable_element("OUTSIDE_BOUNDARY_OBJECT")

        when "SURFACE"
          disable_element("VIEW_FACTOR_TO_GROUND")
          enable_element("OUTSIDE_BOUNDARY_OBJECT")

          object_names = Plugin.model_manager.input_file.find_objects_by_class_name("FENESTRATIONSURFACE:DETAILED").collect { |object| object.name }
          set_select_options("OUTSIDE_BOUNDARY_OBJECT", object_names.sort)

        when "OTHERSIDECOEFFICIENTS"
          disable_element("VIEW_FACTOR_TO_GROUND")
          enable_element("OUTSIDE_BOUNDARY_OBJECT")

          object_names = Plugin.model_manager.input_file.find_objects_by_class_name("SURFACEPROPERTY:OTHERSIDECOEFFICIENTS").collect { |object| object.name }
          set_select_options("OUTSIDE_BOUNDARY_OBJECT", object_names.sort)

        when "GROUND", "GROUNDFCFACTORMETHOD", "GROUNDSLABPREPROCESSORAVERAGE",
              "GROUNDSLABPREPROCESSORCORE", "GROUNDSLABPREPROCESSORPERIMETER",
              "GROUNDBASEMENTPREPROCESSORAVERAGEWALL", "GROUNDBASEMENTPREPROCESSORAVERAGEFLOOR", 
              "GROUNDBASEMENTPREPROCESSORUPPERWALL", "GROUNDBASEMENTPREPROCESSORLOWERWALL",
              "ZONE", "OTHERSIDECONDITIONSMODEL"  # Not sure what to do with the last two here!
          disable_element("VIEW_FACTOR_TO_GROUND")
          disable_element("OUTSIDE_BOUNDARY_OBJECT")

        else  # Blank
          disable_element("VIEW_FACTOR_TO_GROUND")
          disable_element("OUTSIDE_BOUNDARY_OBJECT")
        end
      end

    end


  end

end
