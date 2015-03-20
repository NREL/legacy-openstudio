# OpenStudio
# Copyright (c) 2008-2013, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("legacy_openstudio/lib/dialogs/DialogInterface")
require("legacy_openstudio/lib/dialogs/DefaultConstructionsDialog")


module LegacyOpenStudio

  class DefaultConstructionsInterface < DialogInterface

    def initialize
      super
      @dialog = DefaultConstructionsDialog.new(nil, self, @hash)
    end

  end

end
