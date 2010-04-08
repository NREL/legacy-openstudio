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
      
      @last_report = ''
      @hash['LAST_REPORT'] = @last_report
    end
    
    def last_report=(text)
      @last_report = text
    end
    
    def populate_hash
      @hash['LAST_REPORT'] = @last_report
      super
    end
    
    def report
      super
    end
    

   
  end

end
