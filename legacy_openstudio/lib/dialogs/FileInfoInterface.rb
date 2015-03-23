# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/dialogs/DialogInterface")
require("legacy_openstudio/lib/dialogs/FileInfoDialog")


module LegacyOpenStudio

  class FileInfoInterface < DialogInterface

    def initialize
      super
      @dialog = FileInfoDialog.new(nil, self, @hash)
    end


    def populate_hash
      if (Plugin.model_manager.input_file.path.nil?)
        @hash['NAME'] = "Untitled.idf"
        @hash['PATH'] = "(Never saved)"
        @hash['SIZE'] = ""
      else
        @hash['NAME'] = File.basename(Plugin.model_manager.input_file.path)
        @hash['PATH'] = Plugin.model_manager.input_file.path

        if (File.exist?(Plugin.model_manager.input_file.path))
          size = (File.size(Plugin.model_manager.input_file.path) / 1000).to_s
        else
          size = "0"
        end

        @hash['SIZE'] = size + " KB"
      end

      num_zones = Plugin.model_manager.input_file.find_objects_by_class_name("Zone").count
      num_bases = Plugin.model_manager.input_file.find_objects_by_class_name("BuildingSurface:Detailed").count
      num_subs = Plugin.model_manager.input_file.find_objects_by_class_name("FenestrationSurface:Detailed").count
      num_shading = Plugin.model_manager.input_file.find_objects_by_class_name("Shading:Zone:Detailed", "Shading:Building:Detailed", "Shading:Site:Detailed").count

      num_objs = Plugin.model_manager.input_file.objects.count
      num_other = num_objs - num_zones - num_bases - num_subs - num_shading

      @hash['ZONES'] = num_zones.to_s
      @hash['BASE_SURFACES'] = num_bases.to_s
      @hash['SUB_SURFACES'] = num_subs.to_s
      @hash['SHADING_SURFACES'] = num_shading.to_s
      @hash['OTHER_OBJECTS'] = num_other.to_s
      @hash['TOTAL_OBJECTS'] = num_objs.to_s
    end

  end

end
