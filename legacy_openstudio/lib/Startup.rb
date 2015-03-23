# OpenStudio
# Copyright (c) 2008-2015, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.


# This script simply loads the rest of the plugin

#$debug = true


# check the Ruby version, if necessary.  So far the included Ruby interpreter works fine for everything.
# if (RUBY_VERSION < '1.8.0')


if (RUBY_PLATFORM =~ /mswin/ || RUBY_PLATFORM =~ /mingw/)  # Windows
  minimum_version = '8.0.0000'
  minimum_version_key = '0008000000000'
elsif (RUBY_PLATFORM =~ /darwin/)  # Mac OS X
  minimum_version = '8.0.0000'
  minimum_version_key = '0008000000000'
end

installed_version = Sketchup.version
installed_version_key = ''; installed_version.split('.').each { |e| installed_version_key += e.rjust(4, '0') }

if (installed_version_key < minimum_version_key)
  UI.messagebox("OpenStudio is only compatible with SketchUp version " + minimum_version +
    " or higher.\nThe installed version is " + installed_version + ".  The plugin was not loaded.", MB_OK)
else
  # start legacy plugin after everything and check for OpenStudio already loaded
  UI.start_timer(1, false) { 
    begin
      # Test if OpenStudio is loaded, Kernel.const_defined?(OpenStudio) did not work in SU 8
      OpenStudio
      OpenStudio::Plugin
      
      # UI.MessageBox was being called repeatedly, maybe because it was blocking?
      if Sketchup.version_number > 14000000     
        SKETCHUP_CONSOLE.show
      end
      puts "OpenStudio is already loaded, disable OpenStudio using 'Window->Preferences->Extensions' to use the Legacy OpenStudio Plug-in."
      
    rescue
      
      # only load this if OpenStudio is not installed
      load("legacy_openstudio/lib/PluginManager.rb")

    end
  }
end
