# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.
#
# The Collection class is a variety of a "set"--an unordered collection of objects with uniqueness.
# A Set class is already implemented in the SketchUp API, but this class has some extended
# capabilities and the advantage that it can be used outside of SketchUp.
# Also Collection never contains nil in its collection.

require("legacy_openstudio/lib/Bag")


module LegacyOpenStudio

  class Collection < Bag

    # Add an object to the Bag, no duplicates!
    def add(this_object)
      if (this_object and not contains?(this_object))
        @objects << this_object
      end
      return(self)
    end


    # Add all of the objects from another Bag or an Array, no duplicates!
    def merge(this_object)
      if (this_object.class == self.class)
        @objects += this_object.to_a
      elsif (this_object.class == Array)
        this_object.each { |object| add(object) }
      else
        # Could throw an error
        puts "Collection.merge:  unhandled argument class"
      end
      return(self)
    end

  end

end
