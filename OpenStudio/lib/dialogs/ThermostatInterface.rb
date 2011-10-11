# OpenStudio
# Copyright (c) 2008-2011, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("OpenStudio/lib/dialogs/DialogInterface")
require("OpenStudio/lib/dialogs/ThermostatDialog")

module OpenStudio

  class ThermostatInterface < DialogInterface

    def initialize
      super
      @dialog = ThermostatDialog.new(nil, self, @hash)
    end
    
    def to_new
      @dialog.to_new
    end
    
    def to_existing
      @dialog.to_existing
    end
    
  end

end
