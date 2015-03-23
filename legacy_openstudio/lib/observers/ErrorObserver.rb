# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

$exception = nil

def detect_errors

  if (($! or $exception) and not $debug)
    if ($!)
      $exception = $!
    end

    backtrace = $exception.backtrace

    # NOTE:  There is a difference in backtrace with different versions of the Ruby Interpreter.
    #        V 1.8.0 returns ["file path:line"] for a file or ["(eval):#"] for Ruby Console command line.
    #        V 1.8.6 returns ["file path:line","(eval):#"] for a file or ["(eval):#"] for Ruby Console command line.
    path_line = backtrace[0].split(':')
    if (path_line.length > 1)
      path = path_line[0] + ':' + path_line[1]  # Colon here is to handle C: in the path


      if (path.include?(LegacyOpenStudio::Plugin.dir))

        msg = "Sorry...the plugin has encountered an error.  "
        msg += "This error may cause unpredictable behavior in the plugin--continue this session with caution!  "
        msg += "It would probably be a good idea to exit SketchUp and start again.\n\n"

        msg += "For help, please visit <http://openstudio.sourceforge.net> to join the user support mailing list, "
        msg += "browse the list of known issues in the bug tracker, or post a new bug report.\n\n"

        msg += "When reporting a bug, please include the error message and backtrace below (scroll down):\n\n"

        msg += "ERROR:\n"
        msg += $exception.class.to_s + "\n"
        msg += $exception.message + "\n\n"

        msg += "BACKTRACE:\n"

        $exception.backtrace.each { |stack_call|
          msg += stack_call + "\n"
        }

        UI.messagebox(msg, MB_MULTILINE, LegacyOpenStudio::Plugin.name + " - Error Alert")

      else
        # Not an OpenStudio bug!
      end

      $exception = nil
      $! = nil  # Clear the error so this does not keep getting called
    end
  end

end
