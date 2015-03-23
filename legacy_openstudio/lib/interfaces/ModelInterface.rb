# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/Collection")

require("legacy_openstudio/lib/interfaces/SurfaceGeometry")
require("legacy_openstudio/lib/interfaces/Location")
require("legacy_openstudio/lib/interfaces/Building")
require("legacy_openstudio/lib/interfaces/Zone")
require("legacy_openstudio/lib/interfaces/BaseSurface")
require("legacy_openstudio/lib/interfaces/SubSurface")
require("legacy_openstudio/lib/interfaces/AttachedShadingSurface")
require("legacy_openstudio/lib/interfaces/DetachedShadingSurface")
require("legacy_openstudio/lib/interfaces/OtherInterfaces")
require("legacy_openstudio/lib/interfaces/SimpleGeometry")
require("legacy_openstudio/lib/interfaces/DaylightingControls")
require("legacy_openstudio/lib/interfaces/OutputIlluminanceMap")

require("legacy_openstudio/lib/observers/ModelObserver.rb")
require("legacy_openstudio/lib/observers/ModelEntitiesObserver.rb")


module LegacyOpenStudio

  class ModelInterface

    attr_accessor :input_file, :model, :model_path
    attr_accessor :parent, :children, :observer, :entities_observer   # for debugging only


    def initialize(input_file = nil)
      @parent = nil
      @children = Collection.new  # GlobalGeometryRules, Building, Location, Zones, and Shading Groups

      @input_file = input_file
      @model = Sketchup.active_model
      @model_path = Sketchup.active_model.path

      @observer = nil
      @entities_observer = nil

      # Setup the class lookup hash for creating drawing interfaces from input objects.
      @class_hash = Hash.new
      @class_hash['GLOBALGEOMETRYRULES'] = SurfaceGeometry
      @class_hash['BUILDING'] = Building
      @class_hash['SITE:LOCATION'] = Location
      @class_hash['ZONE'] = Zone
      @class_hash['BUILDINGSURFACE:DETAILED'] = BaseSurface
      @class_hash['FENESTRATIONSURFACE:DETAILED'] = SubSurface
      @class_hash['SHADING:ZONE:DETAILED'] = AttachedShadingSurface
      @class_hash['SHADING:BUILDING:DETAILED'] = DetachedShadingSurface
      @class_hash['SHADING:SITE:DETAILED'] = DetachedShadingSurface
      #@class_hash['MATERIAL'] = Material
      #@class_hash['CONSTRUCTION'] = Construction
      #@class_hash['DAYLIGHTING:DETAILED'] = DaylightingDetailed
      @class_hash['DAYLIGHTING:CONTROLS'] = DaylightingControls
      @class_hash['OUTPUT:ILLUMINANCEMAP'] = OutputIlluminanceMap

      # Setup the order in which interfaces are drawn in the model.
      @draw_order = [SurfaceGeometry, Building, Location, Zone, BaseSurface, SubSurface, AttachedShadingSurface, DetachedShadingSurface, DaylightingControls, OutputIlluminanceMap]
    end


    def inspect
      return(to_s)
    end


    # Check for initial errors that could be bad for drawing the input file.
    # Child drawing interfaces check each input object separately.
    def check_input_file

      if (@input_file.find_objects_by_class_name("GlobalGeometryRules").empty?)
        drawing_interface = SurfaceGeometry.new
        drawing_interface.create_input_object  # Adds input object to the input file, but not as a child interface yet.
        drawing_interface.update_input_object

        Plugin.model_manager.add_error("Error:  Missing the required GlobalGeometryRules object.\n")
        Plugin.model_manager.add_error("A new GlobalGeometryRules object has been added.\n\n")
      end

      if (@input_file.find_objects_by_class_name("Building").empty?)
        drawing_interface = Building.new
        drawing_interface.create_input_object  # Adds input object to the input file, but not as a child interface yet.
        drawing_interface.update_input_object

        Plugin.model_manager.add_error("Error:  Missing the required Building object.\n")
        Plugin.model_manager.add_error("A new Building object has been added.\n\n")
      end

      if (@input_file.find_objects_by_class_name("Site:Location").empty?)
        drawing_interface = Location.new
        drawing_interface.create_input_object  # Adds input object to the input file, but not as a child interface yet.
        drawing_interface.update_input_object

        Plugin.model_manager.add_error("Error:  Missing the required Site:Location object.\n")
        Plugin.model_manager.add_error("A new Site:Location object has been added.\n\n")
      end

      # Convert all simplified geometry objects to detailed ones.
      SimpleGeometry.convert_to_detailed(@input_file)

      return(true)
    end


    def on_change_input_file_path
      if (Sketchup.active_model and @input_file)
        @model.input_file_path = @input_file.path
      end
    end


    def draw_model(update_progress = nil)
      if (check_input_file)
        update_model(update_progress)
        #check_model  # bad do check here.  observers have already been added.
      end
      return(true)
    end


    # Updates the model with the current state of the input file.
    # This method does all of the drawing of new entities or updating of existing entities.
    def update_model(update_progress = nil)
      remove_observers

      @model.input_file_path = @input_file.path  # similar to:  @entity.input_object_key = @input_object.key

      # Create hash table of entities that have an EnergyPlus key.
      # (Meaning they were associated with an input object at one time.)
      # NOTE:  This currently requires that SurfaceGroups are all at the top level (no nesting) 
      #        and all Surfaces are located at the top level inside of a SurfaceGroup.
      #        This might have to be revisited later.
      entity_hash = Hash.new
      for entity in Sketchup.active_model.entities
        if (entity.class == Sketchup::Group and entity.input_object_key)
          # This is a SurfaceGroup.
          entity_hash[entity.input_object_key] = entity
          entity.drawing_interface = nil  # Partially clean these.  The old object references are all invalid, but keep the input object key value.

          # Iterate over surfaces in the group.
          for child_entity in entity.entities
            if (entity.class == Sketchup::Face and entity.input_object_key)
              # This is a Surface.
              entity_hash[entity.input_object_key] = entity
              entity.drawing_interface = nil  # Partially clean these.  The old object references are all invalid, but keep the input object key value.
            end
          end
        end
      end


      # Loop through the input file and create an interface for each drawable input object.
      # Input objects that do not have a corresponding drawing interface are ignored.
      drawing_interfaces = Array.new
      for input_object in @input_file.objects
        if (this_class = @class_hash[input_object.class_name.upcase])
          drawing_interfaces.push(this_class.new_from_input_object(input_object))
        end
      end

      # Sort the drawing interfaces according to the "draw order".
      drawing_interfaces.sort! { |a, b| @draw_order.index(a.class) <=> @draw_order.index(b.class) }

      # Reattach drawing interfaces and entities.
      for drawing_interface in drawing_interfaces
        # Delete each pair from the hash as it is found for efficiency.
        drawing_interface.entity = entity_hash.delete(drawing_interface.input_object.key)
        
        # drawing_interface.set_entity(entity_hash.delete(drawing_interface.input_object.key)) maybe?
        #   I'm effectively doing 'drawing_interface.new_from_input_object_and_entity'
      end

      # Erase unattached entities.
      unattached_entities = entity_hash.values
      @model.entities.erase_entities(unattached_entities)

      # Reconstruct all the DetachedShadingGroup interfaces.  Because they are not derived from input objects,
      # they must be artificially reassociated with the groups around detached shading surfaces.
      shading_interfaces = drawing_interfaces.find_all { |interface| interface.class == DetachedShadingSurface }
      for drawing_interface in shading_interfaces
        if (drawing_interface.entity)
          group = drawing_interface.entity.parent.instances.first
          if (not group.drawing_interface)
            shading_interface = DetachedShadingGroup.new_from_entity(group)
            shading_interface.surface_type = drawing_interface.surface_type
          end
        end
      end


      # Missing zones named by base surfaces and zones for other orphans could also be added here.
      # That might be a lot cleaner than doing it inside the child interface.


      # Draw all the drawing interfaces.  Existing entities will be updated which may even erase and redraw.
      count = drawing_interfaces.length
      drawing_interfaces.each_with_index { |interface, i|
        if (update_progress)
          update_progress.call((100 * i / count), "Drawing Objects")
        end
        interface.draw_entity(false)  # False indicates not to use observers; they are added in bulk later.
      }

      if (update_progress)
        update_progress.call(100, "Finalizing Drawing")
      end

      check_model

      # After everything is drawn and finished changing, add the observer classes.
      add_observers
    end


    # Final check for any errors (generated by the plugin) in the drawing after opening a file.
    def check_model
      recurse_children.each { |child| child.cleanup_entity }
    end


    def erase_model
      remove_observers  # This really speeds up the erase when deleting many entities at once

      entities = @children.collect { |interface| interface.entity if (interface.valid_entity? and (interface.class == Zone or interface.class == DetachedShadingGroup)) }

      @model.close_active
      @model.entities.erase_entities(entities.to_a)
    end


    def clean_model
      recurse_children.each { |interface| interface.clean_entity }
    end


    def on_save_model
      @model_path = Sketchup.active_model.path
    end


    def add_observers
      recurse_children.each { |interface| interface.add_observers }
      @model.entities.add_observer(@entities_observer = ModelEntitiesObserver.new)
    end


    def remove_observers
      if (@entities_observer)
        @model.entities.remove_observer(@entities_observer)
      end
      recurse_children.each { |interface| interface.remove_observers }
    end


    def add_child(child)
      @children.add(child)
    end


    def remove_child(child)
      @children.remove(child)
    end


    def recurse_children
      interfaces = Collection.new(@children)
      @children.each { |interface| interfaces.merge(interface.recurse_children) }
      return(interfaces)
    end


    def has_surface_groups?
      for entity in @model.entities
        next if (entity.class != Sketchup::Group)
        return(true) if (entity.input_object_key)
      end
      return(false)
    end


  end

end
