# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/inputfile/FieldDefinition")
require("legacy_openstudio/lib/inputfile/ClassDefinition")


module LegacyOpenStudio

  class DataDictionary
  
    attr_reader :path, :object_list_hash, :class_hash
    

    def DataDictionary.open(path)
      return(new(path))
    end

    def initialize(path)
    
      if (path.nil?)
      
        puts "DataDictionary.initialize:  no path"
        
      elsif (not File.exist?(path))
      
        puts "DataDictionary.initialize:  bad path"
        
      else

        # check for cached file
        cached_path = path + ".cache"
        if File.exists?(cached_path) and (File.new(path).mtime < File.new(cached_path).mtime)
                  
          # load cached file
          File.open(cached_path, 'r') do |file|
            cached = Marshal.load(file)
            @path = cached.path
            @object_list_hash = cached.object_list_hash
            @class_hash = cached.class_hash
          end
                  
        else
        
          @path = path
          @object_list_hash = Hash.new
          @class_hash = Hash.new

          parse  # need a way to indicate error on return
          
          # path may not be writable, File.writable? is not giving good results
          begin
            # save to cache
            File.open(cached_path, 'w') do |file|
              Marshal.dump(self, file)
            end
          rescue
          end
          
        end
        
      end
    end
    
    
    def DataDictionary.version(path)
      version_string = nil

      if (File.exist?(path))
        idd = File.open(path, 'r')

        if (not idd)
          puts "DataDictionary.version:  error opening IDD"
        else
          line = idd.gets

          # First line of IDD is formatted as "!IDD_Version 3.0.0.028"
          #if (match_data = line.match(/\d+(\.\d+)*/))  # Matches 3.0.0.028
          if (match_data = line.match(/\d+\.\d+\.\d+/))  # Matches 3.0.0
            version_string = match_data[0]
          end

          idd.close
        end
      end

      return(version_string)
    end

    def inspect
      # This method prevents the Ruby Console from getting bogged down by trying to print all objects in the IDF.
      return(self)
    end


    def get_class_def(name)
      return(@class_hash[name.strip.upcase])
    end

    def test_write
      # A test method to dump the contents of the IDD instance for verification
      # May want to replace with some unit testing instead

      dmp = File.new(File.dirname(@path) + '/idd-dump.csv', 'w')

      dmp.puts "Number,Name,Type,SI Units,IP Units,Ref,Ref Keys"

      for class_def in @class_hash.values
        dmp.puts 'Object="' + class_def.name + '"'

        for i in 1...class_def.field_definitions.length
          field = class_def.field_definitions[i]

          line = 'Field #' + i.to_s + ',"' + field.name + '",' + field.type + ',"' + field.units_si +
            '","' + field.units_ip + '","' + field.ref + '",'

          for key in field.object_list_keys
            line += key + '  '
          end

          dmp.puts line

          #puts "  References"
        end

        dmp.puts

      end

      dmp.close

    end


  private

    def parse
    
      # This routine parses the IDD and creates a local database of object and field definitions
      # Currently, ~98% of objects in the IDD are handled; WindowGlassSpectralData is one that is not.

      sort_index = 0
      
      # current group
      group = ""

      if (not File.exist?(@path))
        puts "error opening IDD"
      else
        idd = File.open(@path, 'r')

        if (not idd)
          puts "error 2 opening IDD"
        else
          # Read the IDD and parse

          while (line = idd.gets)

            if (line.strip.empty?)
              # Blank line
              next
            elsif (line.strip[0..0] == '!')
              # Comment-only line
              next
            elsif (line.strip[0..5] == '\group')
              # Group description line
              group = line[(6)..(line.length)].strip
              next
            elsif (not line.index(',') and not line.index(';'))
              # Other unimportant lines
              next
            else
              # Object start line
              class_def = ClassDefinition.new
              sort_index += 1
              class_def.sort_index = sort_index
              
              # set the group
              class_def.group = group
  
              # set the name
              if (i = line.index(','))
                class_def.name = line[0...i].strip
              elsif (i = line.index(';'))
                class_def.name = line[0...i].strip
              end

              # Create a quick lookup hash table
              @class_hash[class_def.name.upcase] = class_def

              class_def.field_definitions = [ nil ]
              last_field = false

              # Parse the field definitions
              while (line = idd.gets)

                if (i = line.index("\\unique-object"))
                  class_def.unique = true
                elsif (i = line.index("\\min-fields"))
                  class_def.min_fields = line[(i + 12)..(line.length)].strip.to_i
                elsif (i = line.index("\\field"))
                  field_def = FieldDefinition.new
                  field_def.name = line[(i + 7)..(line.length)].strip
                  field_def.type = line.strip[0..0]

                  class_def.field_definitions << field_def

                  if (line[0..i].index(';'))
                    last_field = true
                  end
                elsif (i = line.index("\\required-field"))
                  if (defined? field_def)
                    field_def.required = true
                    if ((class_def.field_definitions.length - 1) > class_def.min_fields)
                      class_def.min_fields = class_def.field_definitions.length - 1
                    end
                  end
                elsif (i = line.index("\\key"))
                  if (defined? field_def)
                    field_def.choice_keys += [ line[(i + 5)..(line.length)].strip ]
                  end
                elsif (i = line.index("\\default"))
                  if (defined? field_def)
                    field_def.default_value = line[(i + 9)..(line.length)].strip
                  end
                elsif (i = line.index("\\units"))
                  if (defined? field_def)
                    field_def.units_si = line[(i + 7)..(line.length)].strip
                  end
                elsif (i = line.index("\\ip-units"))
                  if (defined? field_def)
                    field_def.units_ip = line[(i + 10)..(line.length)].strip
                  end
                elsif (i = line.index("\\reference"))
                  if (defined? field_def)
                    key = line[(i + 11)..(line.length)].strip
                    field_def.object_list_keys << key
                    
                    # Add key to object_list_hash
                    if (not @object_list_hash.has_key?(key))
                      @object_list_hash[key] = []
                    end
                    
                  end
                  
                elsif (i = line.index("\\object-list"))
                  if (defined? field_def)
                    field_def.object_list = line[(i + 13)..(line.length)].strip
                  end
                  
                end

                #if (last_field && line.strip.empty?) then break end
                if (line.strip.empty?) then break end


              end  #while

            end

          end  #while

        end
      end

      return(true)
    end

  end


end
