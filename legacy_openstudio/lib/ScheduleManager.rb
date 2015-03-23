# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

module LegacyOpenStudio

  # A class to hold the definitions for schedules
  # Later this will be expanded to allow the user to create/edit/delete schedules
  class ScheduleManager

    def initialize

    end
    
    def new_schedule_stub

      if (results = UI.inputbox(['Schedule Name:  '], [''], 'Add New Schedule Stub'))
        if (results[0].empty?)
          UI.messagebox("You must enter a name to create a new schedule.\nNo object was created.")
        else
          name = results[0]

          # Lookup existing schedule objects
          schedules = Plugin.model_manager.input_file.find_objects_by_class_name("SCHEDULE:YEAR", "SCHEDULE:COMPACT", "SCHEDULE:FILE", "SCHEDULE:CONSTANT")

          if (schedules.find { |schedule| schedule.name == name })
            UI.messagebox('The name "' + name + '" is already in use by another schedule object.' + "\nNo object was created.")
          else
            input_object = InputObject.new("Schedule:Compact")
            input_object.name = name

            Plugin.model_manager.input_file.add_object(input_object)

            UI.messagebox("The new schedule object was successfully created!\nDon't forget to edit the input file outside of SketchUp to define the schedule.")
          end

        end
      end

    end

  end

end
