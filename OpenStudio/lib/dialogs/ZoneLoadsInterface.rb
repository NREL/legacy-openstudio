# OpenStudio
# Copyright (c) 2008-2012, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("OpenStudio/lib/dialogs/DialogInterface")
require("OpenStudio/lib/dialogs/ZoneLoadsDialog")

module OpenStudio

  class ZoneLoadsInterface < DialogInterface

    def initialize
      super
      @dialog = ZoneLoadsDialog.new(nil, self, @hash)
    end  
    
  end

end
