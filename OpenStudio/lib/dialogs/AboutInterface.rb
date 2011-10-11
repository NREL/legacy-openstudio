# OpenStudio
# Copyright (c) 2008-2011, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("OpenStudio/lib/dialogs/DialogInterface")
require("OpenStudio/lib/dialogs/AboutDialog")


module OpenStudio

  class AboutInterface < DialogInterface

    def initialize
      super
      @dialog = AboutDialog.new(nil, self, @hash)
    end

  end

end
