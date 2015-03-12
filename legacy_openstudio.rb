######################################################################
#  Copyright (c) 2008-2014, Alliance for Sustainable Energy.  
#  All rights reserved.
#  
#  This library is free software; you can redistribute it and/or
#  modify it under the terms of the GNU Lesser General Public
#  License as published by the Free Software Foundation; either
#  version 2.1 of the License, or (at your option) any later version.
#  
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  Lesser General Public License for more details.
#  
#  You should have received a copy of the GNU Lesser General Public
#  License along with this library; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
######################################################################

require 'extensions.rb'   # defines the SketchupExtension class

# move the Energy+.idd file in the old install out of the way
remove_plugin = Sketchup.find_support_file("Energy+.idd", "Plugins/OpenStudio")
if remove_plugin
  File.move(remove_plugin, remove_plugin + ".removed")
end

old_plugin = Sketchup.find_support_file("Energy+.idd", "Plugins/legacy_openstudio")
old_version = nil
if old_plugin
  
  # peek at Idd to figure out version
  old_version = "Unknown"
  File.open(old_plugin, 'r') do |file|
    line = file.gets
    if /IDD_Version 4\.0\.0/.match(line)
      old_version = "1.0.4"
    elsif /IDD_Version 5\.0\.0/.match(line)
      old_version = "1.0.5"
    elsif /IDD_Version 6\.0\.0/.match(line)
      old_version = "1.0.6"
    elsif /IDD_Version 7\.0\.0/.match(line)
      old_version = "1.0.7"
     elsif /IDD_Version 7\.1\.0/.match(line)
      old_version = "1.0.8"     
     elsif /IDD_Version 7\.2\.0/.match(line)
      old_version = "1.0.9"     
     elsif /IDD_Version 8\.0\.0/.match(line)
      old_version = "1.0.10"     
     elsif /IDD_Version 8\.1\.0/.match(line)
      old_version = "1.0.11.414"     
    end
  end
  
  OPENSTUDIO_PLUGIN_NAME = "Legacy OpenStudio"
  OPENSTUDIO_PLUGIN_VERSION = old_version
end
  
ext = SketchupExtension.new(OPENSTUDIO_PLUGIN_NAME, "legacy_openstudio/lib/Startup.rb")
ext.name = OPENSTUDIO_PLUGIN_NAME
ext.description = "Adds building energy modeling capabilities by coupling SketchUp to the EnergyPlus simulation engine.  \r\n\r\nVisit www.energyplus.gov for more information."
ext.version = old_version
ext.creator = "National Renewable Energy Laboratory"
ext.copyright = "2008-2014, Alliance for Sustainable Energy"

# 'true' automatically loads the extension the first time it is registered, e.g., after install
Sketchup.register_extension(ext, true)

