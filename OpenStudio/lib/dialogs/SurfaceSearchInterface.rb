# OpenStudio
# Copyright (c) 2008-2009 Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("OpenStudio/lib/dialogs/DialogInterface")
require("OpenStudio/lib/dialogs/SurfaceSearchDialog")

module OpenStudio

  class SurfaceSearchInterface < DialogInterface

    def initialize
      super
      @dialog = SurfaceSearchDialog.new(nil, self, @hash)
    end
    
  end

end
