# OpenStudio
# Copyright (c) 2008-2012, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("OpenStudio/lib/dialogs/DialogInterface")
require("OpenStudio/lib/dialogs/SurfaceMatchingDialog")

module OpenStudio

  class SurfaceMatchingInterface < DialogInterface

    def initialize
      super
      @dialog = SurfaceMatchingDialog.new(nil, self, @hash)
    end
    
  end

end
