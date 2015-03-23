# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/dialogs/Dialogs")


module LegacyOpenStudio

  class BaseSurfaceInfoPage < Page

    def add_callbacks
      super
      @container.web_dialog.add_action_callback("on_change_element") { |d, p| on_change_element(d, p) }
    end


    def on_load
      #super

      # Populate zone list
      object_names = Plugin.model_manager.input_file.find_objects_by_class_name("ZONE").collect { |object| object.name }
      if (not object_names.contains?(@hash['ZONE']))
        object_names.add(@hash['ZONE'])
      end
      set_select_options("ZONE", object_names.sort)

      # Populate construction list
      object_names = Plugin.model_manager.construction_manager.constructions.collect { |object| object.name }
      if (not object_names.contains?(@hash['CONSTRUCTION']))
        object_names.add(@hash['CONSTRUCTION'])
      end
      set_select_options("CONSTRUCTION", object_names.sort)

      on_change_boundary_condition(nil)

      #super

      # Don't set the background color because it causes the dialog to flash.
      #@container.execute_function("setBackgroundColor('" + default_dialog_color + "')")
      
      update_units
      update
    end


    def on_change_element(d, p)
      last_boundary_condition = @hash['OUTSIDE_BOUNDARY_CONDITION']
      super
      on_change_boundary_condition(last_boundary_condition)
      report
    end


    def on_change_boundary_condition(last_boundary_condition)
    
      case (@hash['OUTSIDE_BOUNDARY_CONDITION'])

      when "OUTDOORS"
      
        if not last_boundary_condition.nil? and not last_boundary_condition.empty? and not last_boundary_condition == "OUTDOORS"
          @hash['SUN'] = true
          @hash['WIND'] = true
        end
        @hash['OUTSIDE_BOUNDARY_OBJECT'] = ""

        enable_element("SUN")
        enable_element("WIND")
        enable_element("VIEW_FACTOR_TO_GROUND")
        disable_element("OUTSIDE_BOUNDARY_OBJECT")
        set_select_options("OUTSIDE_BOUNDARY_OBJECT", [""])

       when "ADIABATIC"
        @hash['VIEW_FACTOR_TO_GROUND'] = "0.0"
        @hash['OUTSIDE_BOUNDARY_OBJECT'] = ""
        
        enable_element("SUN")
        enable_element("WIND")
        disable_element("VIEW_FACTOR_TO_GROUND")
        disable_element("OUTSIDE_BOUNDARY_OBJECT")
        set_select_options("OUTSIDE_BOUNDARY_OBJECT", [""])

      when "GROUND", "GROUNDFCFACTORMETHOD", "GROUNDSLABPREPROCESSORAVERAGE",
              "GROUNDSLABPREPROCESSORCORE", "GROUNDSLABPREPROCESSORPERIMETER",
              "GROUNDBASEMENTPREPROCESSORAVERAGEWALL", "GROUNDBASEMENTPREPROCESSORAVERAGEFLOOR", 
              "GROUNDBASEMENTPREPROCESSORUPPERWALL", "GROUNDBASEMENTPREPROCESSORLOWERWALL"
        @hash['SUN'] = false
        @hash['WIND'] = false
        @hash['VIEW_FACTOR_TO_GROUND'] = "0.0"
        @hash['OUTSIDE_BOUNDARY_OBJECT'] = ""

        disable_element("SUN")
        disable_element("WIND")
        disable_element("VIEW_FACTOR_TO_GROUND")
        disable_element("OUTSIDE_BOUNDARY_OBJECT")
        set_select_options("OUTSIDE_BOUNDARY_OBJECT", [""])
        
      when "SURFACE"
        @hash['SUN'] = false
        @hash['WIND'] = false
        @hash['VIEW_FACTOR_TO_GROUND'] = "0.0"
        
        disable_element("SUN")
        disable_element("WIND")
        disable_element("VIEW_FACTOR_TO_GROUND")
        enable_element("OUTSIDE_BOUNDARY_OBJECT")
        object_names = Plugin.model_manager.input_file.find_objects_by_class_name("BUILDINGSURFACE:DETAILED").collect { |object| object.name }
        set_select_options("OUTSIDE_BOUNDARY_OBJECT", object_names.sort)
        
      when "ZONE"
        @hash['SUN'] = false
        @hash['WIND'] = false
        @hash['VIEW_FACTOR_TO_GROUND'] = "0.0"

        disable_element("SUN")
        disable_element("WIND")
        disable_element("VIEW_FACTOR_TO_GROUND")
        enable_element("OUTSIDE_BOUNDARY_OBJECT")
        object_names = Plugin.model_manager.input_file.find_objects_by_class_name("ZONE").collect { |object| object.name }
        set_select_options("OUTSIDE_BOUNDARY_OBJECT", object_names.sort)

      when "OTHERSIDECOEFFICIENTS"
        @hash['VIEW_FACTOR_TO_GROUND'] = "0.0"

        enable_element("SUN")
        enable_element("WIND")
        disable_element("VIEW_FACTOR_TO_GROUND")
        enable_element("OUTSIDE_BOUNDARY_OBJECT")
        object_names = Plugin.model_manager.input_file.find_objects_by_class_name("SURFACEPROPERTY:OTHERSIDECOEFFICIENTS").collect { |object| object.name }
        set_select_options("OUTSIDE_BOUNDARY_OBJECT", object_names.sort)

      when "OTHERSIDECONDITIONSMODEL"
        @hash['VIEW_FACTOR_TO_GROUND'] = "0.0"

        enable_element("SUN")
        enable_element("WIND")
        disable_element("VIEW_FACTOR_TO_GROUND")
        enable_element("OUTSIDE_BOUNDARY_OBJECT")
        object_names = Plugin.model_manager.input_file.find_objects_by_class_name("SURFACEPROPERTY:OTHERSIDECONDITIONSMODEL").collect { |object| object.name }
        set_select_options("OUTSIDE_BOUNDARY_OBJECT", object_names.sort)
        
      end
      
    end

  end

end
