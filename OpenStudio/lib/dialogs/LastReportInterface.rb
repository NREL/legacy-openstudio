# OpenStudio
# Copyright (c) 2008-2009 Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require("OpenStudio/lib/dialogs/DialogInterface")
require("OpenStudio/lib/dialogs/LastReportDialog")


module OpenStudio

  class LastReportInterface < DialogInterface

    def initialize
      super
      @dialog = LastReportDialog.new(nil, self, @hash)
      
      @hash['LAST_REPORT'] = ''
    end
    
    def last_report=(text)
      @hash['LAST_REPORT'] = text
      @dialog.update
    end
   
  end

end
