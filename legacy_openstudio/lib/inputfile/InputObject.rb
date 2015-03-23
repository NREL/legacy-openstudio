# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/inputfile/DataDictionary")


module LegacyOpenStudio

  # Container for IDF objects read during open
  class InputObject

    attr_accessor :class_definition, :context, :dependents, :fields, :deleted


    def initialize(class_name, fields = nil, context = nil)
      @deleted = false
      @context = ''

      if (@class_definition = Plugin.data_dictionary.get_class_def(class_name))
      
        if (fields.nil? or fields.empty?)
          @fields = @class_definition.default_values  # Fill minimum and required defaults
        else
          @fields = fields
        end

        #@saved_context = @context  # Backup original context in case it needs to be restored later

        if (context.nil? or context.empty?)
          @context = format_context()
        else
          @context = context
        end
      end

      @dependents = []  # Pointers to other objects that reference this object; gets filled in externally.
    end


    def InputObject.new_from_idf(idf_string)

      lines = idf_string.split(/\n/)
      context = ''
      field_num = 0
      fields = []
      line_fields = []

      for line in lines

        b = 0

        if (i = line.index('!'))
          line_no_comment = line[0...i] + ' '  # Remove end-line comment; Add space so that fields.pop doesn't accidentally delete a field in the case of ",!"
        else
          line_no_comment = line + ' '  # safety space in case line ends with a comma with nothing after it
        end

        semicolon_line = line_no_comment.index(';')
        comma_line = line_no_comment.index(',')

        if (semicolon_line or comma_line)

          # Remove anything after the first semicolon
          if (semicolon_line)
            line_no_comment = line_no_comment[0...semicolon_line] + ','  # Replace the semicolon with a comma
          end

          # Split line into comma-delimited fields
          line_fields = line_no_comment.split(/,/)

          # Strip leading and trailing white space
          line_fields.each {|f| f.strip!}

          # Remove the last field if it is blank--an artifact of the split method
          line_fields.pop if (not line_fields.last.nil? and line_fields.last.empty?)

          # Replace field values with tokens
          for n in 0...line_fields.length
            field = line_fields[n]
            token = '%' + field_num.to_s
            if (field.empty?)

              # Look for n-th comma and insert token
              count = 0
              a = 0
              loop do
                if (a = line.index(',', a))
                  count += 1
                  break if (count == (n + 1))
                else
                  break  # No more commas
                end
                a += 1
              end
              line.insert(a, token)
              
              b = a + token.length  # Make sure next replace starts looking after this token

            else

              # Look for the field text and replace with token
              a = line.index(field, b)
              b = a + field.length
              line = line[0...a] + token + line[b..-1]
              
              b = a + token.length  # Make sure next replace starts looking after this token

            end

            field_num += 1
          end

          fields += line_fields
        end

        context += line + "\n"
      end

      # Strip certain vestigial input objects that are still in some input files but do nothing.
      # DesignBuilder stills adds these.
      case (fields[0].upcase)
      when "LEAD INPUT", "END LEAD INPUT", "SIMULATION DATA", "END SIMULATION DATA"
        Plugin.model_manager.input_file.modified = true
        return(nil)
      end

      if (class_def = Plugin.data_dictionary.get_class_def(fields[0]))
        fields[0] = class_def.name
        return(InputObject.new(fields[0], fields[0..-1], context))
      else
        # Need a nicer way to pass an error back
        Plugin.model_manager.add_error("Error:  Unidentified EnergyPlus class " + fields[0].to_s + ".\n")
        Plugin.model_manager.add_error("The object could not be parsed.  You might have old version of EnergyPlus or an old IDD--try transitioning your file to the latest version.\n\n")
        return(nil)
      end

    end


    def eql?(other_object)
      return(other_object.class == InputObject and @fields == other_object.fields and @context == other_object.context)
    end


    def ==(other_object)
      return(eql?(other_object))
    end


    def deleted?
      return(@deleted)
    end


    # Creates an identical copy of the object with identical name.
    # Use InputFile.copy_object to make a copy with a new unique name in that input file.
    # (Unique name only makes sense in the context of an input file.)
    def copy
      object_copy = self.dup
      object_copy.fields = @fields.dup
      object_copy.dependents = @dependents.dup
      object_copy.context = @context.dup
      return(object_copy)
    end


    def to_a
      return @fields
    end


    def to_short_s
      return to_a.join(",") + ";"
    end


    alias_method :_to_s, :to_s

    def to_s
      # This is essential for when a field references this object and must convert the array element into a string on write.
      return(name)
    end


    def inspect
      return(_to_s)
    end


    def class_name
      return(@class_definition.name)
    end


    def is_class_name?(name)
      return(name.upcase == class_name.upcase)
    end


    def name
      # Warning:  Not all objects have a name in field 1
      # Need to check if even has a name!  Look at field_def name.
      if (@fields[1].class == InputObject)
        return(@fields[1].name)
      else
        return(@fields[1])
      end
    end


    def name=(new_name)
      @fields[1] = new_name
    end


    def key
      return(class_name.to_s + ', ' + name.to_s)
    end


    #def fields
    #  return(@fields)
    #end
    
    # probably means you can't set individual fields, e.g., obj.fields[3] = "EXTERIOR"
    
    #def fields=(array)
    #  @fields = array
    #  @class_name = array[0]
      
      # lookup the obj_def
      
      # update any dependencies or references
    
    #end



    # Inserts current field values into context string
    def to_idf
      format_context()
      context = @context.gsub(/%\d+/) { |token| n = token[1..-1].to_i; next(@fields[n].to_s) }
      return(context)
    end


    # creates initial context
    # appends any new fields at a later time
    # reformats to different specs (match IDF Editor, match IDD, etc.)
    # save original context to @saved_context
    # context always contains tokens embedded in it.
    # writes in standard IDD format
    # add option to put vertices on one line
    # add option to put report variables on one line  (maybe read from IDD?)
# - append new fields, remove old fields
# - check for required commas and semicolons...insert if needed    
    def format_context

      if (@context.nil? or @context.empty?)
      #  # Add a token for the class name
      #  if (@fields.length == 1)
          context = "  %0;\n"
      #  else
      #    context = "  %0,\n"
      #  end
      else
        context = @context
      end

      token_count = context.scan(/%\d+/).length
      field_count = @fields.length

# could compile the regexp to be faster!

      if (token_count > field_count)
        # Remove extraneous tokens
        n = field_count
        token = '%' + n.to_s
        while (i = context.index(token))

          # Remove token and its comma or semicolon
          context.sub!(/#{token}(\s*(,|;))?/, '')
          # can probably cutoff trailing comments here too

          n += 1
          token = '%' + n.to_s
        end


        # There are fewer fields than before--change last comma to a semicolon
        token = '%' + (field_count - 1).to_s
        if (seg = context.scan(/#{token}\s*,/)[0])
          seg.sub!(/,/, ';')
          context.sub!(/#{token}\s*,/, seg)
          
          # Remove any trailing comments, namely old field names.
          i = context.index(/#{token}\s*;.*\n/)
          last_line = context.scan(/#{token}\s*;.*\n/)[0]
          context = context[0..i + last_line.length]
        end

        # Because there are less fields than before, the endline comments for the old fields will
        # still be present.  This is because it's difficult to distinguish between endline comments
        # and other context following the object that might be desirable to keep.
        # One possible solution would be to eliminate all trailing comments.  Could be a user option.
      end


      if (token_count < field_count)
        # There are more fields than before--change last semicolon to a comma
        token = '%' + (token_count - 1).to_s
        if (seg = context.scan(/#{token}\s*;/)[0])
          seg.sub!(/;/, ',')
          context.sub!(/#{token}\s*;/, seg)
        end

        # Append new tokens
        for n in token_count...field_count
          if (n == (field_count - 1))
            separator = ';'
          else
            separator = ','
          end

          token = '%' + n.to_s
          field_string = '    ' + token + separator

          if (field_def = @class_definition.field_definitions[n])
            field_name = field_def.name

            if (field_def.units_si.empty?)
              units = ''
            else
              units = ' {' + field_def.units_si + '}'
            end

            context += field_string + '  !- ' + field_name + units + "\n"
          else
            # Should only get here if extra fields have been added that are not in the IDD class definition.
            context += field_string + "\n"
          end

        end
      end

      @context = context
    end


  end


end
