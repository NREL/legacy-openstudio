# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.


module UI

  # Executes a system command, e.g., "dir", "cd c:/xyz", "copy a b", etc.
  # Other Ruby methods such as 'exec' or 'system' by themselves do not seem to work well.
  # TIPS:
  #   Commands don't always work the way they do in the MS-DOS shell window, best to experiment to find what works.
  #   Use 'start' or 'cmd' to launch a new shell that will stay open.
  #   Use 'call xyz.html' to open a file in a new default web browser.
  #   Use double quotes around file paths with spaces.
  #   Both file separators \ and / are accepted.  Make sure to double up on the \\.
  #   Use '&&' to put multiple commands in the same string, e.g., "dir && pause"  NOTE:  Doesn't seem to work for all commands.
  def UI.shell_command(command_string, asynchronous = true)
    if (asynchronous)
      result = Thread.new { system(command_string) }  # Returns a Thread object asynchronously, i.e., the command continues running independently.
    else
      result = system(command_string)  # Returns true AFTER the command completes.
    end
    return(result)
  end


  # This a cross-platform way to open a file outside of SketchUp, e.g., text, html, pdf, etc.
  # The system file associations determine which program to use to open the file.
  # This is an alternative to using UI.openURL which always hijacks whatever browser is open
  # on the users desktop on Windows.  UI.openURL does not seem to work at all on the Mac.
  def UI.open_external_file(path)
    if (path.nil?)
      puts "UI.open_external_file:  nil path specified."
    else
      if (RUBY_PLATFORM =~ /mswin/ || RUBY_PLATFORM =~ /mingw/)  # Windows
        UI.shell_command('start "Open File" "' + path + '"')
      elsif (RUBY_PLATFORM =~ /darwin/)  # Mac OS X
        UI.shell_command('open "' + path + '"')
      else
        puts "UI.open_external_file:  unhandled platform."
      end
    end
  end


  # This patch allows all file separators to be accepted and prints an error message if path does not exist.
  # Decided that the normal behavior of UI.openpanel should not be changed (even for the better).
  # New alternative method is:  UI.open_panel
  def UI.open_panel(*args)
    if (args[1])
      dir = args[1]
      
      if (not dir.empty?)

        if (RUBY_PLATFORM =~ /mswin/ || RUBY_PLATFORM =~ /mingw/)  # Windows
          # Replace / with \\ for the file separator
          dir = dir.split("/").join("\\")

          # Check for and append required final \\
          if (dir[dir.length - 1].chr != "\\")
            dir += "\\"
          end

        else  # Mac
          # Check for and append required final /
          if (dir[dir.length - 1].chr != "/")
            dir += "/"
          end
        end

        if (not File.directory?(dir))
          puts "UI.open_panel received bad directory: " + dir
          args[1] = ""
        else
          args[1] = dir
        end
      end
    end

    # Allow empty file name to be passed in as a valid argument
    if (args[2])
      if (args[2].strip.empty?)
        args[2] = "*.*"
      end
    else
      args[2] = "*.*"
    end

    #if (path = _openpanel(*args))
    if (path = UI.openpanel(*args))  # call the original method
      # Replace \\ with / for the file separator (works better for saving the path in a registry default)
      path = path.split("\\").join("/")
    end

    return(path)
  end


  # Decided that the normal behavior of UI.savepanel should not be changed (even for the better).
  # New alternative method is:  UI.save_panel
  def UI.save_panel(*args)
    if (args[1])
      dir = args[1]
      
      if (not dir.empty?)
      
        if (RUBY_PLATFORM =~ /mswin/ || RUBY_PLATFORM =~ /mingw/)  # Windows
          # Replace / with \\ for the file separator
          dir = dir.split("/").join("\\")

          # Check for and append required final \\
          if (dir[dir.length - 1].chr != "\\")
            dir += "\\"
          end

        else  # Mac
          # Check for and append required final /
          if (dir[dir.length - 1].chr != "/")
            dir += "/"
          end
        end
      
        if (not File.directory?(dir))
          puts "UI.save_panel received bad directory: " + dir
          args[1] = ""
        else
          args[1] = dir
        end
      end
    end

    # Allow empty file name to be passed in as a valid argument
    if (args[2])
      if (args[2].strip.empty?)
        args[2] = "*.*"
      end
    else
      args[2] = "*.*"
    end

    #if (path = _savepanel(*args))
    if (path = UI.savepanel(*args))  # call the original method
      # Replace \\ with / for the file separator (works better for saving the path in a registry default)
      path = path.split("\\").join("/")
    end

    return(path)
  end

  
end
