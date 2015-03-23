# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/Collection")
require("legacy_openstudio/lib/inputfile/DataDictionary")
require("legacy_openstudio/lib/inputfile/InputObject")


module LegacyOpenStudio

# needs a copy method

  class InputFile

    def InputFile.open(data_dictionary, path, update_progress = nil)
      input_file = new(data_dictionary, update_progress)
      input_file.open(path)
      return(input_file)
    end

    attr_accessor :path, :modified, :objects, :deleted_objects, :new_objects, :context  # not sure if modified should be here, already have 'modified?' method


    def initialize(data_dictionary, update_progress = nil)  # called by InputFile.new

      if (data_dictionary.nil?)
        puts "InputFile.initialize:  no data dictionary"

      else
        @data_dictionary = data_dictionary
        @object_list_hash = @data_dictionary.object_list_hash.clone

        @path = nil
        @modified = false

        @context = ""
        @objects = Collection.new
        @new_objects = Collection.new
        @deleted_objects = Collection.new

        @update_progress = update_progress
      end

    end


    def open(path)
      @path = path
      
      if (File.exist?(path))
        merge(path)
        @modified = false
      else
        puts "InputFile.open:  bad path"
      end
    end

# could put all File.exist? checking at the read_file, write_level

    def copy
      new_input_file = dup
      # hash needs to be copied too, but it's not exposed.
      new_input_file.objects = @objects.dup
      new_input_file.new_objects = @new_objects.dup
      new_input_file.deleted_objects = @deleted_objects.dup
      return(new_input_file)
    end


    def merge(path)
      if (File.exist?(path))
        read_file(path)  
        
        
        # if this was canceled, or there was an error, 'read_file' should return an error code.
        
        update_object_references
        @modified = true
      else
        puts "InputFile.merge:  bad path"
      end
    end


    def write(path = nil, update_progress = nil)
      if (path.nil?)
        path = @path
      end

      success = write_file(path, update_progress)

      if (success)
        @modified = false
      end

      return(success)
    end


    def writable?  # not used yet
      # if the file has not been written yet, might want to check path to make sure dir exists, etc.
      if (@path and File.exist?(@path))
        return(File.writable?(@path))
      else
        return(false)
      end
    end


    def modified?
      return(@modified)
    end


    def sort
      # sort by zone, by IDD

      # needs to interface with 'write' method to really work

      array = @objects.sort
    end


    def inspect
      # This method prevents the Ruby Console from getting bogged down by trying to print all objects in the IDF.
      return(to_s)
    end


    def test_write
      # for testing
      print "dumping IDF...\n"

      for object in @objects
        print object.to_idf
      end
    end


    def new_unique_object_name
      while (true) # 'loop do' doesn't work?
        # Generate a random 5 digit hex number in the range 10000 to FFFFF
        #new_name = (rand(983040) + 65536).to_s(16).upcase

        # Generate a random 6 digit hex number in the range 100000 to FFFFFF  (=15,728,639 unique names)
        new_name = (rand(15728640) + 1048576).to_s(16).upcase

        # Or try license plate style:  ABC-123

        # Check to make sure the name is not already in use (by chance!).
        # This is actually a stricter check than EnergyPlus actually performs.
        # EnergyPlus only cares about duplicate names within a specific object class.
        for object in @objects
          next if (object.name == new_name)
        end
        break  # Not a duplicate name
      end

      return(new_name)
    end


    # Object methods

    def add_object(object, set_modified = true)
      # When an object is added, InputFile could check its references, and check for errors (duplicates).
      # When reading a file, this is probably not desireable.  Want to do two passes.  So should have a silent mode.

      @objects.add(object)
      @new_objects.add(object)
      if (set_modified)
        @modified = true
      end
    end


    # Copy the object, give it a new unique name, and add it to the input file.
    def copy_object(object, set_modified = true)
      # When an object is added, InputFile could check its references, and check for errors (duplicates).
      # When reading a file, this is probably not desireable.  Want to do two passes.  So should have a silent mode.

      object_copy = object.copy
      object_copy.name = new_unique_object_name  # This won't work for objects without a name, e.g., Version

      add_object(object_copy)
      if (set_modified)
        @modified = true
      end

      return(object_copy)
    end


    def new_object(class_name, fields = nil)
      object = InputObject.new(class_name)
      object.class_definition = @data_dictionary.get_class_def(class_name)  # this is way more work than I should be doing here...

      if (not fields.empty?)
        object.fields = fields
        # add to file 'context' based on ordering/formatting rules
      end

      add_object(object)
      return(object)
    end


    def new_object_from_fields(fields)
      object = InputObject.new
      if (not fields.empty?)
        object.fields = fields
        object.class_definition = @data_dictionary.get_class_def(fields[0])  # this is way more work than I should be doing here...
        
        # add to file 'context' based on ordering/formatting rules
      end

      add_object(object)
      return(object)
    end


    # Tests whether an object exists in the input file and was not deleted.
    def object_exists?(this_object)
      return(@objects.contains?(this_object))
    end


    def find_object_by_id(object_id)
      return(@objects.find { |object| object.object_id == object_id })
    end


    def find_objects_by_class_name(*args)
      found_objects = Collection.new
      for arg in args
        found_objects += @objects.find_all { |object| object.is_class_name?(arg) }
      end
      return(found_objects)
    end


    def find_object_by_class_and_name(class_name, object_name)
      return(@objects.find { |object| object.is_class_name?(class_name) and object.name == object_name })
    end


    def delete_object(object)
      object.deleted = true
      @deleted_objects.add(object)
      @objects.remove(object)
      @modified = true
    end


    def undelete_object(object)
      object.deleted = false
      @objects.add(object)
      @deleted_objects.remove(object)
      @modified = true
    end


  private

    # Reads and parses the file
    def read_file(path)
      $read_file_canceled = false

      file = File.open(path, 'r')

      buffer = ""
      inside_object = false
      end_object = false

      file_length = 0
      file_size = File.size(path)

      while (line = file.gets)
      
        file_length += line.length + 1  # For update_progress

        if (i = line.index('!'))
          line_no_comment = line[0...i]  # Remove end-line comment
        else
          line_no_comment = line
        end

        semicolon_line = line_no_comment.index(';')
        comma_line = line_no_comment.index(',')
        blank_line = line.strip.empty?  # White space only

        if (semicolon_line or comma_line or blank_line)

          if (end_object)
            # Finalize the object
            if (object = InputObject.new_from_idf(buffer))
              @objects.add(object)
              buffer = ""
              @context += "OBJ#" + object.object_id.to_s + "\n"  # Insert token
              inside_object = false
              end_object = false
              object_key = object.key
            else
              buffer = ""
              inside_object = false
              end_object = false
              object_key = "*BAD OBJECT*"
            end

            if (not @update_progress.nil?)
              continue = @update_progress.call((100 * file_length / file_size), "Reading Input Objects")
              if (not continue)
                puts "break"
                break
              end
            end

          end

          buffer += line


          if (semicolon_line)

            inside_object = true
            end_object = true  # Do not finalize now because there might be trailing comments

          elsif (comma_line)

            inside_object = true

          elsif (blank_line)

            unless inside_object
              @context += buffer
              buffer = ""
            end

          end

        else  # Other line:  comment, macro, or user error/typo

          buffer += line

        end
      end

      # Take care of left-over text in the buffer
      if (inside_object)
        # Finalize the object
        if (object = InputObject.new_from_idf(buffer))
          @objects.add(object)
          @context += "OBJ#" + object.object_id.to_s + "\n"  # Insert token
          object_key = object.key
        else
          object_key = "BAD OBJECT"
        end
        
        if (not @update_progress.nil?)
          @update_progress.call(100, "Reading Input Objects")
        end       
      else
        @context += buffer
      end

      file.close
      
      if Sketchup.version_number > 14000000
        if !@context.valid_encoding?
          @context = @context.encode("UTF-16be", :invalid=>:replace, :replace=>"?").encode('UTF-8')
        end
      end

      if (false) #$debug)
        file = File.open(Plugin.dir + "/z_file_string_dump.idf", 'w')
        file.puts @context #.dump
        file.close

        file = File.open(Plugin.dir + "/z_parsed_dump.idf", 'w')
        @objects.each do |obj|
          file.puts "OBJ#" + obj.object_id.to_s
          file.puts obj.context
          file.puts
        end
        file.close
      end


      #rescue Exception => error_string
      #  puts error_string

      #ensure
        # This code always gets called

    end


    def update_object_references  #update_references   # find_references   find_dependents
     
      # Build object list hash, add all objects that have \reference
      # this could be done during reading/parsing of the file

      total_objects = @objects.count
      count = 0

      for object in @objects
      
        count += 1
        if (not @update_progress.nil?)
          continue = @update_progress.call((100 * count / total_objects), "Updating Object References, First Pass")
          if (not continue)
            break
          end
        end
        
        if object.class_definition.name.upcase == "VERSION"
          version_string = DataDictionary::version(@data_dictionary.path)
          version_pattern = Regexp.new("^#{Regexp.escape(version_string)}")
          
          # pad idf_version_string with 0's if neccesary
          idf_version_string = object.fields[1].to_s
          if not idf_version_string.match(/\d+\.\d+\.\d+/)
            if idf_version_string.match(/\d+\.\d+/)
              idf_version_string += ".0"   # if version string = 7.0
            else
              idf_version_string += ".0.0" # if version string = 7
            end
          end

          if not version_pattern.match(idf_version_string)
            Plugin.model_manager.add_error("Warning:  " + "Idf file '#{path}' has version '#{object.fields[1]}', plugin version is '#{version_string}'\n")
            Plugin.model_manager.add_error("Please convert your file to the plugin version using the EnergyPlus transition program for best results.\n\n")
          end
        end

        if (not object.class_definition)
        
          # Kludge to skip the error message for certain vestigial input objects that are still in the IDD but do nothing.
          # DesignBuilder stills adds these.
          next if (object.is_class_name?("LEAD INPUT"))
          next if (object.is_class_name?("END LEAD INPUT"))
          next if (object.is_class_name?("SIMULATION DATA"))
          next if (object.is_class_name?("END SIMULATION DATA"))

          puts "InputObject encountered with no definition in the DataDictionary (IDD):  " + object.class_name
          puts "Maybe the wrong IDD version or input file is out-of-date."

          # This breaks InputFile's independence but will work for the short term
          Plugin.model_manager.add_error("Warning:  " + "InputObject encountered with no definition in the DataDictionary (IDD):  " + object.class_name + "\n")
          Plugin.model_manager.add_error("Maybe the wrong IDD version or input file is out-of-date.\n\n")

          next
        end

        if (object.class_definition.field_definitions.length > 1)
          field_def = object.class_definition.field_definitions[1]  # pretty safe to say any \reference is in the first field
          # might consider a flag on class_def to say whether it has references

          if (field_def.object_list_keys.length)
            for key in field_def.object_list_keys
              #@object_list_hash[key] << object # DLM@20090904: this line breaks the ability to reopen a model cleanly
              @object_list_hash[key] += [object] # DLM@20090904: this original line works
            end
          end
        end

      end


      count = 0
      # this must only be done after all objects are parsed
      for object in @objects
      
        count += 1
        if (not @update_progress.nil?)
          continue = @update_progress.call((100 * count / total_objects), "Updating Object References, Second Pass")
          if (not continue)
            break
          end
        end

        # search through all fields and replace \object-list name with the actual object reference

        if (not object.class_definition)
          #puts "InputObject encountered with no definition in the DataDictionary (IDD):  "  + object.class_name
          #puts "Maybe the wrong IDD or input file is out-of-date."
          next
        end

        for i in 1...object.fields.length

          if (field_def = object.class_definition.field_definitions[i])
            object_list = field_def.object_list

            if (not object_list.empty?)
              object_array = @object_list_hash[object_list]

              if (object_array)
                for other_object in object_array
                  if (other_object.name.upcase == object.fields[i].upcase)
                    # Replace object name with the object reference
                    object.fields[i] = other_object
                    other_object.dependents << object 
                    break
                    # what if there is more than 1 with this name in here?  dupe names should be flagged elsewhere
                  end
                end
                # if not found, the object name for the non-existent object remains...should be flagged
              end
            end
          end
        end
      end

    end


    def write_file(path, update_progress = nil)
      # put formatting flags here for:  indent spacing, comment separator, comments column #, compressed option, etc.

      # Append new objects to the file context string
      for object in @new_objects
        @context += "\nOBJ#" + object.object_id.to_s + "\n"
      end
      @new_objects.clear


      file = File.new(path, 'w')

      if (false)  # do format
        # call a sort, this will change the context string entirely
      end

      count = 0
      total_objects = @objects.count
      #puts "total objects= " + total_objects.to_s

      lines = nil
      if Sketchup.version_number > 14000000     
        lines = @context.split(/\n/)
      else
        lines = @context.split(/\n/)
      end

      while (line = lines.shift)

        if (line[0..3] == "OBJ#")

          object_id = line[4..-1]
          object = find_object_by_id(object_id.to_i)

          if (object)
            file.puts(object.to_idf)
            
            count += 1            
            if (not update_progress.nil?)
              #puts count
              continue = update_progress.call((100 * count / total_objects), "Writing Objects")
              if (not continue)
                break
              end
            end
          else

            # Object was deleted--skip forward until the next non-blank line
            while (line = lines.shift)
              if (not line.strip.empty?)
                break
              end
            end
            redo if (line)  # If line is nil here, there are no more lines to process.
          end

        else
          # User comments or blank line
          file.puts(line)
        end

      end

      #rescue Exception => error_string
      #  puts error_string

      #ensure
        # This code always gets called
        file.close

      return(true)  # The return status determines whether modified can be set to false
    end

  end

end
