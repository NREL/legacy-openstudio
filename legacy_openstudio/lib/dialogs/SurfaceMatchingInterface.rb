# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/dialogs/DialogInterface")
require("legacy_openstudio/lib/dialogs/SurfaceMatchingDialog")

module LegacyOpenStudio

  class SurfaceMatchingInterface < DialogInterface

    def initialize
      super
      @dialog = SurfaceMatchingDialog.new(nil, self, @hash)
    end
    
  end

end
