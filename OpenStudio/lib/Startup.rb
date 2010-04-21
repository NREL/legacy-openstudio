# OpenStudio
# Copyright (c) 2008-2010, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.


# This script simply loads the rest of the plugin

#$debug = true


# check the Ruby version, if necessary.  So far the included Ruby interpreter works fine for everything.
# if (RUBY_VERSION < '1.8.0')


if (RUBY_PLATFORM =~ /mswin/)  # Windows
  minimum_version = '7.0.0000'
  minimum_version_key = '000700000000'
elsif (RUBY_PLATFORM =~ /darwin/)  # Mac OS X
  minimum_version = '7.0.0000'
  minimum_version_key = '000700000000'
end


installed_version = Sketchup.version
installed_version_key = ''; installed_version.split('.').each { |e| installed_version_key += e.rjust(4, '0') }

if (installed_version_key < minimum_version_key)
  UI.messagebox("OpenStudio is only compatible with Google SketchUp version " + minimum_version +
    " or higher.\nThe installed version is " + installed_version + ".  The plugin was not loaded.", MB_OK)
else
  load("OpenStudio/lib/PluginManager.rb")
end
