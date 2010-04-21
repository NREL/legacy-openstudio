# OpenStudio
# Copyright (c) 2008-2010, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.
#
# The Bag class is an unordered collection of objects where duplicates are allowed.
# Equality of objects is determined by 'equal?' not 'eql?'.  For example, 'equal?'
# matches objects by 'object_id', not by equality of object contents.
# Also Bag never contains nil in its collection.


module OpenStudio

  class Bag

    def initialize(this_object = nil)
      @objects = []
      merge(this_object) if (this_object)
    end


    def inspect
      return(self.to_s + to_a.inspect)
    end


    def clear
      @objects = []
    end


    def to_a
      return(@objects.dup)
    end


    def empty?
      return(@objects.empty?)
    end
    
    
    def length
      return(@objects.length)
    end


    def count
      if (defined?(yield))
        return((find_all { |object| yield(object) }).count)
      else
        return(@objects.length)
      end
    end


    # Add an object to the Bag, duplicates allowed.
    def add(this_object)
      if (this_object)
        @objects << this_object
      end
      return(self)
    end


    # Remove an object (and all its duplicates) from the Bag.
    def remove(this_object)
      @objects.delete_if { |object| object.equal?(this_object) }
      return(self)
    end


    # Add all of the objects from another Bag or an Array, duplicates allowed.
    def merge(this_object)
      if (this_object.class == self.class)
        @objects += this_object.to_a
      elsif (this_object.class == Array)
        @objects += this_object.compact
      else
        # Could throw an error
        puts "Bag.merge:  unhandled argument class"
      end
      return(self)
    end
    

    def each
      @objects.each { |object| yield(object) }
      return(self)
    end
    
    
    def each_index
      @objects.each_index { |object| yield(object) }
      return(self)
    end
    
    
    def [](i)
      return @objects[i]
    end


    def collect
      return(self.class.new(@objects.collect { |object| yield(object) }))
    end


    def remove_if
      @objects.delete_if { |object| yield(object) }
      return(self)
    end


    def find 
      return(@objects.find { |object| yield(object) })
    end


    def find_all
      return(self.class.new(@objects.find_all { |object| yield(object) }))
    end


    def sort
      if (defined?(yield))
        return(@objects.sort { |a, b| yield(a, b) })
      else
        return(@objects.sort)
      end
    end


    def contains?(this_object)
      return(not (@objects.find { |object| object.equal?(this_object) }).nil?)
    end


    def eql?(other_object)
      if (other_object.class == self.class)
        # Compare sizes for a quick check
        if (other_object.count == count)
          # Compare contents
          self_array = @objects.sort
          other_array = other_object.to_a.sort
          for i in 0...self_array.length
            return(false) if (self_array[i] != other_array[i])
          end
          return(true)
        else
          return(false)
        end
      else
        return(false)
      end
    end


    def dup
      return(self.class.new(@objects))
    end


    def clone
      # Not sure how clone and dup are supposed to be different.
      return(dup)
    end


    def ==(other_object)
      return(eql?(other_object))
    end


    # Add two bags to get a new merged bag.
    def +(other_object)
      return(dup.merge(other_object))
    end


    # Other operator methods could be added:
    # bag1 + bag2  # merge
    # bag1 + value  # add item
    # bag1 - bag2  # removes all items in comman
    # bag1 - value  # remove item
    # bag1 & bag2  # intersection

  end

end
