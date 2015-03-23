# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

module LegacyOpenStudio

  class AsynchProc

    def initialize(delay = 50)
    
      seconds = (delay/1000).to_i
      UI.start_timer(seconds, false) {
        begin
          
          # do the proc
          yield

        # Catch the exception here and post it to the ErrorObserver.
        rescue Exception => e
          $exception = $!
          # Most of this code is duplicated in ErrorObserver.detect_errors.
          backtrace = $exception.backtrace
          # NOTE:  There is a difference in backtrace with different versions of the Ruby Interpreter.
          #        V 1.8.0 returns ["file path:line"] for a file or ["(eval):#"] for Ruby Console command line.
          #        V 1.8.6 returns ["file path:line","(eval):#"] for a file or ["(eval):#"] for Ruby Console command line.
          path_line = backtrace[0].split(':')
          if (path_line.length > 1)
            path = path_line[0] + ':' + path_line[1]  # Colon here is to handle C: in the path
            msg = "\nException in AsynchProc!\n"
            msg += "ERROR:\n"
            msg += $exception.class.to_s + "\n"
            msg += $exception.message + "\n"
            msg += "BACKTRACE:\n"
            $exception.backtrace.each { |stack_call| msg += stack_call + "\n" }
            puts msg
          end
        #ensure
        end
      }
      
    end

  end

end
