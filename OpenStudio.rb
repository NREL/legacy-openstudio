# OpenStudio
# Copyright (c) 2008-2011, Alliance for Sustainable Energy.  All rights reserved.
# See the file "License.txt" for additional terms and conditions.

require 'extensions.rb'   # defines the SketchupExtension class

OPENSTUDIO_PLUGIN_NAME = "OpenStudio"
OPENSTUDIO_PLUGIN_VERSION = "1.0.7.<%=svn_revision%>"

ext = SketchupExtension.new(OPENSTUDIO_PLUGIN_NAME, "OpenStudio/lib/Startup.rb")
ext.name = OPENSTUDIO_PLUGIN_NAME
ext.description = "Adds building energy modeling capabilities by coupling SketchUp to the EnergyPlus simulation engine.  \r\n\r\nVisit www.energyplus.gov for more information."
ext.version = OPENSTUDIO_PLUGIN_VERSION
ext.creator = "National Renewable Energy Laboratory"
ext.copyright = "2008-2011, Alliance for Sustainable Energy"

Sketchup.register_extension(ext, true)
# 'true' automatically loads the extension the first time it is registered, e.g., after install
