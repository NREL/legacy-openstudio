# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/sketchup/Geom")


# This file adds new methods to native SketchUp classes.

class Array

  def is_subset_of?(other)
  
    for element in self

      element_matched = false

      for other_element in other
        if (other_element == element)
          element_matched = true
          break
        end
      end

      if (not element_matched)
        # no match
        return(false)
      end
    end
  
    return(true)
  end
  
  
  def is_same_set?(other)
    if (self.length == other.length and self.is_subset_of?(other))
      return(true)
    else
      return(false)
    end
  end

end


class Float

  def round_to(decimal_places = 0)
    if (decimal_places > 0)    
      precision = (10**(decimal_places)).to_f
      return((self * precision).round / precision)
    else
      return(self.round)
    end
  end

end


class Sketchup::Model

  # This attribute is a persistent string reference to an input file.
  # It allows a SketchUp file to be reassociated with the correct input file.
  # Would be nice to allow path strings to be relative to the Model path using standard ./ or ../ syntax.
  # This method would return the adjusted full path.
  def input_file_path
    return(get_attribute('OpenStudio', 'Input File Path'))
  end

  def input_file_path=(path)
    set_attribute('OpenStudio', 'Input File Path', path)
  end

end


class Sketchup::Entity

  # The key is a persistent string reference to an input object in the IDF using "<class name>,<object name>, e.g., "ZONE,Main Zone"
  # This attribute is the only way that a SketchUp object is reassociated with the correct input object when opening an IDF file.
  def input_object_key
    return(get_attribute('OpenStudio', 'Key'))
  end

  def input_object_key=(key_string)
    set_attribute('OpenStudio', 'Key', key_string)
  end


  # 'drawing_interface' is a reference to an instance of DrawingInterface.
  # This attribute provides a link to a DrawingInterface for most geometry operations.
  # This attribute is not meant to be persistent when the file is closed and reopened, although a residual reference number will be saved with the file.
  # NOTE: This method was originally implemented as an attribute on the Entity class (which was intended to be non-persistent).
  #       However, some strange behavior in SketchUp makes face object assignments change around between base surfaces and subsurfaces, so this is a workaround.
  # UPDATE:  I'm not sure this gets me anything anymore.  The face swapping behavior is still a problem.
  #          Only advantage of using attributes is that they get copied to the other face, when divided.
  def drawing_interface
    object = nil
    if (id_string = get_attribute('OpenStudio', 'DrawingInterface'))
      begin
        object = ObjectSpace._id2ref(id_string.to_i)
      rescue
        # The id_string does not reference an existing object!  Ignore the exception.
      ensure
        # Sometimes a bad reference can turn into a real object...but a random one, not the one we want.
        if (object and not object.respond_to?(:draw_entity))
          puts "Entity.drawing_interface:  bad object reference"
          object = nil
          # To detect copy-paste between SketchUp sessions, could set 'object' to a value that can be detected on the
          # receiving end by whichever Observer the entity is pasted into.
        end
      end
    end
    return(object)
  end


  def drawing_interface=(object)
    set_attribute('OpenStudio', 'DrawingInterface', object.object_id.to_s)
  end


  # Because of swapping faces problem, should store this on the drawing interface and only save to the entity as an attribute
  # at save time.
  def input_object_fields
    # store array of fields for checking if file changed, and rebuilding if IDF gets lost.
  end


  def input_object_context
    # optional storage of comments, to rebuild IDF exactly.
  end
  
end



class Sketchup::Color
  # There's still some work to be done here:
  #  Add hue=, saturation=, brightness=
  #  Need reference for the hsba calcs.
  #  There is not a perfect symmetry when converting back and forth between what you put into hsba and what you get back.

  def rgba
    return [red, green, blue, alpha]
  end


  def rgba=(color_array)
    # For some reason, the 'self' is required here or else it doesn't work.
    self.red = color_array[0]
    self.green = color_array[1]
    self.blue = color_array[2]
    self.alpha = color_array[3]
    return(self)
  end


  def hsba
    # HSB = Hue, Saturation, Brightness; identical to HSV = hue, brightness, value
    var_R = red / 255.to_f  # RGB values = 0 � 255
    var_G = green / 255.to_f
    var_B = blue / 255.to_f

    var_Min = [var_R, var_G, var_B].min  # value of RGB
    var_Max = [var_R, var_G, var_B].max  # value of RGB
    del_Max = var_Max - var_Min          # Delta RGB value

    v = var_Max

    if (del_Max == 0)
      # This is a gray, no chroma...
      h = 0  # HSV results = 0 � 1
      s = 0
    else
      # Chromatic data...
      s = del_Max / var_Max

      del_R = ( ( ( var_Max - var_R ) / 6 ) + ( del_Max / 2 ) ) / del_Max
      del_G = ( ( ( var_Max - var_G ) / 6 ) + ( del_Max / 2 ) ) / del_Max
      del_B = ( ( ( var_Max - var_B ) / 6 ) + ( del_Max / 2 ) ) / del_Max

      if (var_R == var_Max)
        h = del_B - del_G
      elsif (var_G == var_Max)
        h = (1 / 3) + del_R - del_B
      elsif (var_B == var_Max)
        h = (2 / 3) + del_G - del_R
      end

      h += 1 if (h < 0)
      h -= 1 if (h > 1)
    end

    return([(h * 360).to_i, (s * 100).to_i, (v * 100).to_i, alpha])
  end


  def hsba=(color_array)
    h = color_array[0] / 360.to_f  # HSV values = 0 � 1
    s = color_array[1] / 100.to_f
    v = color_array[2] / 100.to_f
    a = color_array[3]

    if (s == 0)
      self.red = v * 255
      self.green = v * 255
      self.blue = v * 255
      self.alpha = a
    else
      var_h = h * 6
      var_h = 0 if (var_h == 6)  # H must be < 1
      var_i = var_h.floor
      var_1 = v * (1 - s)
      var_2 = v * (1 - s * (var_h - var_i))
      var_3 = v * (1 - s * (1 - (var_h - var_i)))

      if (var_i == 0)
       var_r = v
       var_g = var_3
       var_b = var_1
      elsif (var_i == 1)
       var_r = var_2
       var_g = v
       var_b = var_1
      elsif (var_i == 2)
        var_r = var_1
        var_g = v
        var_b = var_3
      elsif (var_i == 3)
        var_r = var_1
        var_g = var_2
        var_b = v
      elsif (var_i == 4)
        var_r = var_3
        var_g = var_1
        var_b = v
      else
        var_r = v
        var_g = var_1
        var_b = var_2
      end

      self.red = (var_r * 255).to_i  # RGB results = 0 � 255
      self.green = (var_g * 255).to_i
      self.blue = (var_b * 255).to_i
      self.alpha = a
    end
    return(self)
  end


  def hue
    return hsba[0]
  end


  def saturation
    return hsba[1]
  end


  def brightness
    return hsba[2]
  end


  #def hue=(h)
  #end

end



class Sketchup::Entities

  #alias_method :_add_face, :add_face
  
  # not working yet...
  
  # Override the add_face method to recognize polygons
  def xxx_add_face(*args)
    base_face = nil
    if (args[0].class == Geom::Polygon)
      for polygon_loop in args[0].loops
        face = _add_face(polygon_loop.points)
        #_add_face(polygon_loop.points)

        if (base_face.nil?)
          base_face = face
        end
      end
    else
      #base_face = _add_face(args)
    end
    return(base_face)
  end

end


class Sketchup::Loop

# should this return a polygon or a polygon loop?

  def polygon_loop
    points = []
    self.vertices.each do |vertex| 
      # DLM@20100920: weird bug in SU 8 that vertices can also return attribute dictionary for a loop's vertices
      if vertex.class == Sketchup::Vertex
        points << vertex.position 
      end
    end
    return(Geom::PolygonLoop.new(points))
  end

end




class Sketchup::Face

  def outer_polygon
    return(Geom::Polygon.new(self.outer_loop.polygon_loop))
  end


  def polygon
    this_polygon = self.outer_polygon
    for this_loop in self.loops
      if (not this_loop.outer?)
        this_polygon.add_loop(this_loop.polygon_loop.points)
      end
    end
    return(this_polygon)
  end


  def absolute_polygon
    # Returns the polygon in absolute or "world" coordinates
    if (self.parent.class == Sketchup::ComponentDefinition)
      group = self.parent.instances.first  # Group or ComponentInstance
      transformation = group.transformation
      return(self.polygon.transform(transformation))
    else  # parent is the model object
      return(self.polygon)
    end
  end


  def contains_point?(point, include_border = false)
    return(Geom.point_in_polygon(point, self.polygon, include_border))
  end


  def intersect(other_face)
    return(Geom.intersect_polygon_polygon(self.polygon, other_face.polygon))  # array of polygons
  end

end



class Sketchup::ShadowInfo

  # Still need to reconcile daylight saving time between EnergyPlus and SketchUp
  

  def time
    # API bug:  ShadowTime is returning the hour incorrectly in UTC/GMT time, but the time zone is (correctly) the local one.
    #           Also year is ALWAYS 2002.
    # Example:  Noon on Nov 8 returns Fri Nov 08 04:50:11 Mountain Standard Time 2002
    # SUBTRACT the utc offset to get the correct local time.
    return(convert_to_utc(self['ShadowTime']))
  end


  def time=(new_time)
    # API bug:  ShadowTime is returning the hour incorrectly in UTC/GMT time, but the time zone is (correctly) the local one.
    #           Also year is ALWAYS 2002.
    # Example:  Noon on Nov 8 returns Fri Nov 08 04:50:11 Mountain Standard Time 2002
    # ADD the utc offset to set the correct local time.
    self['ShadowTime'] = new_time + new_time.utc_offset
    # if ShadowTime is already in UTC, this won't do anything...offset = 0
    return(time)
  end


  def dst?
    return(time.dst?)
  end


  def sunrise
    return(convert_to_utc(self['SunRise']))
  end


  def sunset
    return(convert_to_utc(self['SunSet']))
  end


  def zone_offset=(new_zone_offset)
    # Sets the time zone in hours offset from UTC/GMT.  NOTE:  Negative numbers indicate Western hemisphere.
    # API bug:  Setting ShadowTime['TZOffset'] alone does not set this.
    self['TZOffset'] = new_zone_offset
    # No way to change the time zone for the Time object in Ruby...?
    # Might consider putting all time as UTC, handle daylight savings myself.
    return(nil)
  end


private
  def convert_to_utc(time)
    # API bug:  ShadowTime is returning the hour incorrectly in UTC/GMT time, but the time zone is (correctly) the local one.
    #           Also year is ALWAYS 2002.
    # Example:  Noon on Nov 8 returns Fri Nov 08 04:50:11 Mountain Standard Time 2002
    # SUBTRACT the utc offset to get the correct local time.
    a = (time - time.utc_offset).to_a
    return( Time.utc(a[0], a[1], a[2], a[3], a[4], Time.now.year, a[6], a[7], a[8], a[9]) )
  end

end
