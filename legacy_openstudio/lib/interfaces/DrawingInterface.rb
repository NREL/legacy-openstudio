# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/Collection")


module LegacyOpenStudio

  class DrawingInterface

    attr_accessor :input_object, :entity
    attr_accessor :parent, :children, :observer   # for debugging only


    def initialize
      @parent = nil
      @children = Collection.new

      @input_object = nil  # Reference to the EnergyPlus input object:  Zone, Surface, Construction, etc.
      @entity = nil  # Reference to the SketchUp entity:  group, face, material, etc.
      @observer = nil  # This is overridden in each subclass.

      @deleted = false
    end


    def inspect
      return(to_s)
    end


    # Redefine this method so that only a comparison of the same instance of the object will return true.
    # Similar to matching "this.object_id == other.object_id".
    # This is helpful for finding an instance in an array, for example.
    def eql?(this_object)
      return(equal?(this_object))
    end


    # Redefine this method so that only a comparison of the same instance of the object will return true.
    # Similar to matching "this.object_id == other.object_id".
    # This is helpful for finding an instance in an array, for example.
    def ==(this_object)
      return(eql?(this_object))
    end


##### Begin methods for the input object #####


    # Drawing interface is being created because an input object is being loaded.
    # Interface can be drawn later by calling 'draw_entity'.
    def self.new_from_input_object(input_object)
      drawing_interface = new
      drawing_interface.input_object = input_object
      return(drawing_interface)
    end

# check_input_object / accept_input_object?



    # Draws the input object as an entity.
    # This method probably should not be overridden in subclasses; override the internal methods instead.
    # For symmetry this method could be called 'create_from_input_object'.
    #
    # Remove/add of observers is disabled by passing in false as an argument.
    # This allows the model interface to draw many entities without the performance
    # hit to constantly add and remove observers on child and parent.
    # There was also some evidence that too much shuffling of observers was
    # causing BugSplats.
    def draw_entity(use_observers = true)    
      if (check_input_object)
        update_parent_from_input_object  # Needs to happen earlier since @parent is needed in 'check_input_object'

        remove_observers  #if (use_observers)

        if (valid_entity?)  #
          update_entity   # This can call 'erase_entity'/'create_entity'
        else
          create_entity
          update_entity  # This should go away maybe?
        end

        if (confirm_entity)
          @entity.drawing_interface = self
          @entity.input_object_key = @input_object.key if (@input_object)  # Check for DetachedShadingGroups

          paint_entity
          add_observers if (use_observers)
          
          update_input_object
        end
      end

      return(@entity)
    end


    # Creates new defaulted input object and adds it to the input file.
    def create_input_object
      Plugin.model_manager.input_file.add_object(@input_object)
    end


    # This method handles delete status separately from the input object 'deleted?' flag.
    # DetachedShadingGroups don't have an input object but need to have a delete status.
    def deleted?
      return(@deleted)
    end


    # Checks needed before the entity can be drawn.
    # Checks the input object for errors and tries to fix them before drawing the entity.
    # Returns false if errors are beyond repair.
    def check_input_object
      if (@input_object.nil?)
        puts "DrawingInterface.draw_entity:  nil input object"
        return(false)
      else
        return(true)
      end
    end


    # Updates the input object with the current state of the entity.
    def update_input_object
      if (valid_entity?)
        update_parent_from_entity
      end
    end


    # Deletes the input object and marks the drawing interface when the SketchUp entity is erased.
    def delete_input_object
      @deleted = true
      Plugin.model_manager.input_file.delete_object(@input_object) if (@input_object)
      # Don't lose the input object so that it can be restored if it is undeleted.
    end


    # Called by the plugin GUI (currently triggered by user action in the Object Info dialog).
    def on_change_input_object
      draw_entity
    end


    # Called by the plugin GUI (not currently triggered by anything).
    # This could be called from a tree view editor where input objects can be deleted directly.
    def on_delete_input_object
      @deleted = true
      @parent.remove_child(self) if (@parent)  # Duplicate line in 'update_parent_from_entity'
      if (valid_entity?)
        erase_entity
      end
    end


    # Overridden for every subclass.
    def parent_from_input_object
      return(nil)
    end


    # This method should not be overridden by subclasses.
    def update_parent_from_input_object
      @parent.remove_child(self) if (@parent)
      @parent = parent_from_input_object
      @parent.add_child(self) if (@parent)
      
    end


##### Begin methods for the entity #####


    #def self.valid_entity?(entity)
    #  if (entity.nil?)
    #    puts self.to_s + ".valid_entity?:  entity is nil"
    #    return(false)
    #  else
    #    return(true)
    #  end
    #end


    # Error checks before an entity can be accepted by an interface.
    # Does not modify the entity.
    # Returns false if the entity cannot be used.
    #def self.accept_entity?(entity)
    #  if (self.valid_entity?(entity))
    #    return(false)
    #  if (entity.drawing_interface)
    #    puts self.to_s + ".check_entity:  entity already has drawing interface"
    #    return(false)
    #  else
    #    return(true)
    #  end
    #end


    # Drawing interface is being created because a new entity was drawn by the user.
    def self.new_from_entity(entity)
      #if (self.accept_entity?(entity))
        return(self.new.create_from_entity(entity))
      #end
    end


    def create_from_entity(entity)
      @entity = entity
      @entity.drawing_interface = self    
    
      if (check_entity)  # class.check_entity(entity)   # should check before the interface accepts the entity
        #attach_entity(entity)

        create_input_object
        update_input_object

        @entity.input_object_key = @input_object.key

        update_entity
        paint_entity

        add_observers
      else
        puts "DrawingInterface.create_from_entity:  check_entity failed"
      end
      
      return(self)
    end


    # Drawing interface is being created because an entity was copied or divided by the user.
    def self.new_from_entity_copy(entity)
      return(new.create_from_entity_copy(entity))
    end


    def create_from_entity_copy(entity)
      original_interface = entity.drawing_interface

      @entity = entity
      @entity.drawing_interface = self

      if (check_entity)
        if (original_interface.input_object)  # DetachedShadingGroups do not have an input object!
          # Copy the input object so that all user field edits are preserved in the new surface.
          # 'copy_object' gives the input object a new unique name.
          @input_object = Plugin.model_manager.input_file.copy_object(original_interface.input_object)
          @entity.input_object_key = @input_object.key
        end

        update_input_object
        add_observers
      else
        puts "DrawingInterface.create_from_entity_copy:  check_entity failed"
      end
      return(self)
    end


    # Not used yet
    def attach_entity(entity)
      @entity = entity
      @entity.drawing_interface = self
      @entity.input_object_key = @input_object.key if (@input_object)
    end


    # Not used yet
    def detach_entity
      @entity = nil
      @entity.drawing_interface = nil
      @entity.input_object_key = nil
    end


    # Creates the entity appropriate for the class of input object.
    def create_entity
    end


    def valid_entity?
      return(not @entity.nil?)
    end


    # Error checks and cleanup before an entity is accepted by the interface.
    # Return false if the entity cannot be used.
    # Drawing interfaces that don't correspond directly to a geometric entity (e.g., Location, Building)
    # should return false here.
    def check_entity  # accept_entity?
      return(valid_entity?)
    end


    # Error checks, finalization, or cleanup needed after the entity is drawn.
    def confirm_entity
      return(valid_entity?)
    end


    # Updates the entity with the current state of the input object.
    # If necessary, this method will erase and re-draw the entity.
    def update_entity
    end

    # Called by draw_entity, but also can be called independently to repaint everything under different paint modes.
    def paint_entity
      # Probably should remove observers and re-add them after painting.
    end

    def paint_boundary
      #
    end

    def paint_layer
      #
    end

    def paint_normal

    end


    # Final cleanup of the entity.
    # This method is called by the model interface after the entire input file is drawn.
    def cleanup_entity
    end


    def clean_entity
      remove_observers
      if (valid_entity?)
        @entity.delete_attribute('OpenStudio', 'DrawingInterface')
      end
    end


    # Erases the entity when the input object is deleted, or in preparation for a re-draw.
    def erase_entity
      remove_observers
      if (valid_entity?)
        group_entity.entities.erase_entities(@entity)
      end
    end


    def on_change_entity
      update_input_object
      paint_entity  # Needed to fix the floor surface colors after a push/pull into a box.

      # Try this here for a while...
      # When moving a zone this might be ridiculous...Object Info getting hit with some many update requests...
      Plugin.dialog_manager.update(ObjectInfoInterface)
    end


    def on_erase_entity
      @delete = true
      delete_input_object
      @parent.remove_child(self) if (@parent)  # Duplicate line in 'update_parent_from_entity'

      # Try this here for a while...
      # When moving a zone this might be ridiculous...Object Info getting hit with some many update requests...
      Plugin.dialog_manager.update(ObjectInfoInterface)
    end


    # Undelete happens when an entity is restored after an Undo event.
    def on_undelete_entity(entity)
      @deleted = false
      Plugin.model_manager.input_file.undelete_object(@input_object) if (@input_object)

      @entity = entity  # The entity comes back with a different reference than it had originally.
      @entity.drawing_interface = self  # The reference to the drawing interface is lost when it is deleted.
      @entity.input_object_key = @input_object.key if (@input_object)

      on_change_entity  # Restore the parent links, etc.
      add_observers
    end


    # Overridden for every subclass.
    def parent_from_entity
      return(nil)
    end


    # This method should not be overridden by subclasses.
    def update_parent_from_entity
      @parent.remove_child(self) if (@parent)
      @parent = parent_from_entity
      @parent.add_child(self) if (@parent)
    end


    def group_entity
      return(@parent.group_entity)
    end


##### Begin methods for the interface #####


    # Attaches any Observer classes, usually called after all drawing is complete.
    # Also called to reattach an Observer when a drawing interface is restored via undo.
    # This method should be overriden by subclasses.
    def add_observers
      if (valid_entity?)
        @entity.add_observer(@observer)
      end
    end


    # This method can be overriden by subclasses.
    def remove_observers
      if (valid_entity?)
        @entity.remove_observer(@observer)
      end
    end


    # This method should not be overridden by subclasses.
    def add_child(child)
      @children.add(child)
    end


    # This method should not be overridden by subclasses.
    def remove_child(child)
      @children.remove(child)
    end


    # This method should not be overridden by subclasses.
    def recurse_children
      interfaces = Collection.new(@children)
      @children.each { |interface| interfaces.merge(interface.recurse_children) }
      return(interfaces)
    end


  end

end
