# OpenStudio
# Copyright (c) 2008-2009 Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require 'OpenStudio/lib/dialogs/DefaultConstructionsInterface'

module OpenStudio

  # A class to hold the definitions for inside and outside materials
  # Later this will be expanded to allow the user to create/edit/delete constructions and materials
  class ConstructionManager

    attr_reader :floor_ext, :floor_int, :wall_ext, :wall_int, :roof_ext, :roof_int, :window_ext, :window_int, :door_ext, :door_int
    attr_accessor :default_floor_ext, :default_floor_int, :default_wall_ext, :default_wall_int, :default_roof_ext, :default_roof_int
    attr_accessor :default_window_ext, :default_window_int, :default_door_ext, :default_door_int, :default_save_path
    attr_reader :attached_shading, :detached_building_shading, :detached_fixed_shading
    attr_reader :attached_shading_back, :detached_building_shading_back, :detached_fixed_shading_back

    def initialize

      # Materials must be 'in model' to be used on a face
      # 'in model" materials change when a new SU file is created, or an old SU file is opened

      @floor_ext = get_material("EnergyPlus_Floor_Ext", Sketchup::Color.new(128, 128, 128, 1.0))  # old DXF: "Gray"
      @floor_int = get_material("EnergyPlus_Floor_Int", Sketchup::Color.new(191, 191, 191, 1.0))

      @wall_ext = get_material("EnergyPlus_Wall_Ext", Sketchup::Color.new(204, 178, 102, 1.0))  # old DXF: "Lime"
      @wall_int = get_material("EnergyPlus_Wall_Int", Sketchup::Color.new(235, 226, 197, 1.0))

      @roof_ext = get_material("EnergyPlus_Roof_Ext", Sketchup::Color.new(153, 76, 76, 1.0))  # old DXF: "Yellow"
      @roof_int = get_material("EnergyPlus_Roof_Int", Sketchup::Color.new(202, 149, 149, 1.0))

      @window_ext = get_material("EnergyPlus_Window_Ext", Sketchup::Color.new(102, 178, 204, 0.6))  # old DXF: "Cyan"
      @window_int = get_material("EnergyPlus_Window_Int", Sketchup::Color.new(192, 226, 235, 0.6))

      @door_ext = get_material("EnergyPlus_Door_Ext", Sketchup::Color.new(153, 133, 76, 1.0))  # old DXF: "Cyan"
      @door_int = get_material("EnergyPlus_Door_Int", Sketchup::Color.new(202, 188, 149, 1.0))

      @attached_shading = get_material("EnergyPlus_Attached_Shading", Sketchup::Color.new(204, 102, 102, 1.0))  # old DXF: "Magenta"
      @attached_shading_back = get_material("EnergyPlus_Attached_Shading_back", Sketchup::Color.new(230, 182, 182, 1.0))  # old DXF: "Magenta"

      # The detached colors may be breaking from the new DXF color scheme
      @detached_building_shading = get_material("EnergyPlus_Detached_Building_Shading", Sketchup::Color.new(113, 76, 153, 1.0))  # old DXF: "Light Gray"
      @detached_building_shading_back = get_material("EnergyPlus_Detached_Building_Shading_back", Sketchup::Color.new(216, 203, 229, 1.0))

      @detached_fixed_shading = get_material("EnergyPlus_Detached_Fixed_Shading", Sketchup::Color.new(191, 191, 191, 1.0))  # old DXF: "Blue"
      @detached_fixed_shading_back = get_material("EnergyPlus_Detached_Fixed_Shading_back", Sketchup::Color.new(240, 240, 240, 1.0))  # old DXF: "Blue"

      reset_defaults

      # Not needed?:
      #Sketchup.active_model.rendering_options["MaterialTransparency"] = true

    end
    
    
    def reset_defaults
    
      # These default construction names are just suggestions, the user can change them in preferences

      @default_floor_ext = "Exterior Floor"
      @default_floor_int = "Interior Floor"

      @default_wall_ext = "Exterior Wall"
      @default_wall_int = "Interior Wall"

      @default_roof_ext = "Exterior Roof"
      @default_roof_int = "Interior Ceiling"
      
      @default_window_ext = "Exterior Window"
      @default_window_int = "Interior Window"

      @default_door_ext = "Exterior Door"
      @default_door_int = "Interior Door"
      
      @default_save_path = ""
      
    end
    
    
    def check_defaults
      object_names = constructions.collect { |object| object.name }
      object_names = object_names.sort
      
      not_found = []
      
      if not object_names.include?(@default_floor_ext)
        not_found << @default_floor_ext 
        @default_floor_ext = ""
      end
      
      if not object_names.include?(@default_floor_int)
        not_found << @default_floor_int 
        @default_floor_int = ""
      end
      
      if not object_names.include?(@default_wall_ext)
        not_found << @default_wall_ext 
        @default_wall_ext = ""
      end
      
      if not object_names.include?(@default_wall_int)
        not_found << @default_wall_int 
        @default_wall_int = ""
      end
      
      if not object_names.include?(@default_roof_ext)
        not_found << @default_roof_ext 
        @default_roof_ext = ""
      end
      
      if not object_names.include?(@default_roof_int)
        not_found << @default_roof_int 
        @default_roof_int = ""
      end
      
      if not object_names.include?(@default_window_ext)
        not_found << @default_window_ext 
        @default_window_ext = ""
      end
      
      if not object_names.include?(@default_window_int)
        not_found << @default_window_int 
        @default_window_int = ""
      end
      
      if not object_names.include?(@default_door_ext)
        not_found << @default_door_ext 
        @default_door_ext = ""
      end
      
      if not object_names.include?(@default_door_int)
        not_found << @default_door_int 
        @default_door_int = ""
      end
      
      if not_found.size > 0
        result = UI.messagebox("File does not contain default construction names.\nDo you want to set these before drawing new geometry?", MB_YESNO)
        if result == 6 # Yes
          Plugin.dialog_manager.show(DefaultConstructionsInterface)
        end
      end
    end

    def get_material(name, color)
      material = Sketchup.active_model.materials[name]
      if (material.nil?)
        material = Sketchup.active_model.materials.add(name)
        material.color = color
        material.alpha = color.alpha / 255.0
      end
      return(material)
    end
    
    def constructions
      result = Plugin.model_manager.input_file.find_objects_by_class_name("CONSTRUCTION", "CONSTRUCTION:INTERNALSOURCE",
                    "CONSTRUCTION:CFACTORUNDERGROUNDWALL", "CONSTRUCTION:FFACTORGROUNDFLOOR", "CONSTRUCTION:WINDOWDATAFILE")
      return result
    end

    def new_construction_stub

      if (results = UI.inputbox(['Construction Name:  '], [''], 'Add New Construction Stub'))
        if (results[0].empty?)
          UI.messagebox("You must enter a name to create a new construction.\nNo object was created.")
        else
          name = results[0]

          if (constructions.find { |construction| construction.name == name })
            UI.messagebox('The name "' + name + '" is already in use by another construction object.' + "\nNo object was created.")
          else
            input_object = InputObject.new("Construction")
            input_object.name = name

            Plugin.model_manager.input_file.add_object(input_object)

            UI.messagebox("The new construction object was successfully created!\nDon't forget to edit the input file outside of SketchUp to add material layers to the construction.")
          end

        end
      end

    end

  end

end
