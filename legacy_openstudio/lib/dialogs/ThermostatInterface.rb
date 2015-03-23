# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/dialogs/DialogInterface")
require("legacy_openstudio/lib/dialogs/ThermostatDialog")

module LegacyOpenStudio

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
