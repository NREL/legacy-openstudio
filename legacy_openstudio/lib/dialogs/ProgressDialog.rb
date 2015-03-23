# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.


module LegacyOpenStudio

  class ProgressDialog 

    def initialize()
    end

    def update_progress(percent, message = "")
      actual_size = 100
      amount = (percent*actual_size/100).to_i
      Sketchup.status_text = message + "  " + "|"*amount
      return true
    end

    def destroy
      Sketchup.status_text = ""
      return true
    end

  end

end
