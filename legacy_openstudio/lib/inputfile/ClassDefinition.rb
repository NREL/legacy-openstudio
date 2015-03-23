# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.


module LegacyOpenStudio

  class ClassDefinition

    attr_accessor :name, :group, :field_definitions, :unique, :min_fields, :dependents, :sort_index

    def initialize
      @name = ""
      @group = ""
      @field_definitions = []
      @unique = false
      @min_fields = 0
      @sort_index = 0
    end


    def inspect
      return(to_s)
    end


    def default_values
      values = [ @name ]
      for field_def in @field_definitions[1...@min_fields]
        values << field_def.default_value 
      end
      return(values)
    end

  end

end
