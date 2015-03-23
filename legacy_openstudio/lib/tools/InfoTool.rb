# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/tools/Tool")


module LegacyOpenStudio

  class InfoTool < Tool
    # Features To Add:
    #   identify groups as zones (use pickhelper) -- difficult
    #   doubleclick to open a group -- not possible in the API
    #   possible allow changing of selection
    #   with Ctrl key down, it displays construction objects!  --- used to work

    def initialize
      @cursor = UI.create_cursor(Plugin.dir + "/lib/resources/icons/InfoToolCursor-16x17.tiff", 1, 1)
    end


    def onMouseMove(flags, x, y, view)
      super

      # Should apply user's precision setting here
      # Also:  show relative coordinates?
      Sketchup.set_status_text("World Coordinates:  " + @ip.position.to_s)

      if (v = @ip.vertex)
        #Sketchup.set_status_text("World Coordinates:  " + v.position.to_s)
      else
        #    view.tooltip = ""    
        view.tooltip = get_tooltip(@ip.face, flags)
        #Sketchup.set_status_text("")
      end
    end


    def onKeyDown(key, repeat, flags, view)

      # Flags don't seem right here; create new ones from key.
      if (key == CONSTRAIN_MODIFIER_KEY)
        flags = CONSTRAIN_MODIFIER_MASK

      elsif (key == COPY_MODIFIER_KEY)
        flags = COPY_MODIFIER_MASK

      elsif (key == ALT_MODIFIER_KEY)
        flags = ALT_MODIFIER_MASK
      end

      view.tooltip = get_tooltip(@ip.face, flags)
    end


    def onKeyUp(key, repeat, flags, view)
      view.tooltip = get_tooltip(@ip.face, 0)
    end


    def get_tooltip(face, flags)
      if (face)
      
      id_string = face.get_attribute('OpenStudio', 'DrawingInterface')
      #puts(ObjectSpace._id2ref(id_string.to_i))
      #puts face.drawing_interface
      
        if (drawing_interface = face.drawing_interface)
          if (input_object = drawing_interface.input_object)

            if (flags & CONSTRAIN_MODIFIER_MASK > 0)  # Shift key is down

              if (input_object.is_class_name?("BUILDINGSURFACE:DETAILED") or input_object.is_class_name?("FENESTRATIONSURFACE:DETAILED"))
                construction = input_object.fields[3]

                if (construction.class == InputObject)
                  tooltip = construction.to_idf
                else
                  tooltip = input_object.to_idf
                end

              else
                tooltip = input_object.to_idf
              end

            #elsif (flags & COPY_MODIFIER_KEY > 0)  # Ctrl key is down
              # Show material input object
              # Hard part is how to know which side of the face we are looking at?

            else
              tooltip = input_object.to_idf
            end
          else
            tooltip = "Bad DrawingInterface--no InputObject reference."
          end
        else
          tooltip = "No EnergyPlus object found."
        end
      else
        tooltip = ""  
      end

      return(tooltip)
    end


    def onLButtonDoubleClick(flags, x, y, view)
      super

      if (@ip.face)
        $f = @ip.face
        #puts $f
        #puts $f.input_object_key

#        puts "relative coordinates"
#        $f.vertices.each { |v| puts v.position }
#        puts
        
#        puts "insertion point"
#        puts $f.parent.insertion_point

#        t = $f.parent.instances.first.transformation
#        puts "world coordinates"
#        $f.vertices.each { |v| puts (v.position).transform(t) }
#        puts
        

        #puts "DrawingInterface="
        #puts $f.drawing_interface
      end

      if (@ip.edge)
        $e = @ip.edge
      end

      $ip = @ip.position
      
      puts
      puts "Face=>       " + $f.to_s
      puts "Interface=>  " + $f.drawing_interface.to_s
      #puts "EntityID=>   " + $f.entityID.to_s   # useless...always matched to the same Face
      puts "Key=>        " + $f.input_object_key.to_s
      #puts "Base Face=>  " + DrawingUtils.find_base_face($f).to_s   # this is not working right
      puts
      
      $g = $f.parent.instances.first
      
      #puts "Group=>      " + $g.to_s
      #puts "Grp Intrfc=> " + $g.drawing_interface.to_s
      #puts "Entities=>   " + $g.entities.to_s
      #puts "Entities[]=> " + $g.entities.to_a.to_s

      
      #puts $f.entityID
      
      #$f.drawing_interface.surface_polygon.points.each { |v| puts v.display }
      
      #puts $f
      #puts $f.drawing_interface
      #$f.vertices.each { |v| puts v.position.display }
      #puts

      #if ($f.contains_point?(@ip.position, include_border = true))
      #  puts "face contains point"
      #else
      #  puts "face DOES NOT contain point"
      #end
      
    #  puts $f.classify_point($ip)
      # 1 = inside of all edges
      # 2 = on an edge
      # 4 = on a vertex
      # 8 = off the face completely, but still in the same plane
      # 16 = off the face completely, and not even on the same plane
      
      #PointUnknown = 0;
      #PointInside = 1;
      #PointOnEdge = 2;
      #PointOnVertex = 4
      #PointOutside = 8;
      #PointNotOnPlane = 16;

    end

  end

end
