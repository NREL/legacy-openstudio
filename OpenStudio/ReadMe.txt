OpenStudio 1.0.7


Copyright (c) 2008-2011, Alliance for Sustainable Energy.  All rights reserved.
See the file "License.txt" for additional terms and conditions.

Developed by the National Renewable Energy Laboratory, Golden, Colorado for
the United States Department of Energy.


Release Date:  17 October 2011


System Requirements
-------------------
Windows XP/2000/Vista/7 or Mac OS X 10.4+
Google SketchUp 7.0 or later (Free or Pro)
EnergyPlus 6.0

New Features for 1.0.7
----------------------

* Updated for EnergyPlus 7.0.


Bug Fixes for 1.0.7
----------------------

* None


New Features for 1.0.6
----------------------

* Updated for EnergyPlus 6.0.

* Updated for SketchUp 8.0.


Bug Fixes for 1.0.6
----------------------

* Fixed problem causing flickering dialogs

* Fixed problem with push/pull of face in SU 8.

* Fixed problem with push/pull of divided face.


New Features for 1.0.5
----------------------

* Updated for EnergyPlus 5.0.

* Daylighting:Controls and Output:IlluminanceMap Input Objects.

* Surface and sub-surface search.

* Quickly add internal gains and HVACTemplate:Zone:IdealLoadsAirSystem to zones.

* Automatic surface matching and unmatching tool.

* Default construction manager.

* Improved documentation and tutorials.



Bug Fixes for 1.0.5
----------------------

* Improved support for simple geometry.

* Removed dependency on Windows system dlls not shipped with plugin.

* Run EnergyPlus through OpenStudio as a non-admin



New Features for 1.0.4
----------------------

* Updated for EnergyPlus 4.0.

* Improved parsing and caching of eso and idd files.

* Support for template HVAC using ExpandObjects and SQLite output option. 

* Alpha stage functions for matching surfaces and subsurfaces available through the Ruby console.  
  See upcoming_features.html in the documentation.



Bug Fixes for 1.0.4
----------------------

* Fixed bug with data tool when there is no data.



New Features for 1.0.3
----------------------

* Updated for EnergyPlus 3.1.

* First release for Mac OS X.



Bug Fixes for 1.0.3
----------------------

* Fixed bug with Shading:Site:Detailed surfaces getting the building rotation
  applied in relative coordinates.



New Features for 1.0.2
----------------------

* Dialog state and position are saved and restored between SketchUp sessions.

* Check for Update message has option to skip the newer version.



Bug Fixes for 1.0.2
----------------------

* Fixed bug with Run Simulation dialog.

* Fixed bug with results rendering feature.

* Fixed bug where SketchUp would freeze when opening a complex SKP file.

* Fixed bug where erasing a window or a door would unintentionally turn its
  base surface into a window or a door.

* Fixed bug with incorrect warning about windows or doors not being
  contained by their base surfaces.

* Fixed bug where shading groups were causing crashes or freezes.

* Fixed bug where copy and paste of a shading group did not work.

* Fixed bug where cut and undo of a shading group did not work.

* Fixed bug where upside down roofs or floors were not being automatically
  corrected.

* Fixed bug with relative coordinate system.

* Fixed bug with clockwise coordinate system.

* Fixed bug where vertex order was not being honored.



New Features for 1.0.0
----------------------

* Persistent association between the SKP file and IDF file.  When the SKP
  file is opened it remembers which IDF file was previously associated and
  reopens it automatically.  The SketchUp model is automatically re-synched
  to the IDF if any changes were made outside of SketchU by adding, erasing,
  and redrawing surfaces and zones as necessary.

* New toolbar button that connects you directly to the on-line EnergyPlus
  Example File Generator (EEFG) which allows you to automatically generate
  complete building models.  You can also upload your local IDF file (drawn
  with OpenStudio) to EEFG and have it automatically derive a building
  model derived from ASHRAE Standard 90.1.

* Cut/Copy/Paste support for all geometry.

* Undo support for undoing the delete of zones or surfaces.

* More robust tracking of objects added and deleted, and dynamic tracking
  of object relationships (surfaces in zone, sub surfaces on base surfaces).

* More accurate child counts and instant update of all Object Info data.

* More accurate object counts in File Info dialog.

* Default constructions (from NewFileTemplate.idf) are applied to all new
  surfaces as drawn.

* Instant update of Location data in Simulation Info window.

* New toolbar buttons to quickly access the help documentation (User Guide),
  the Outliner window, and to toggle SketchUp's Hide Rest of Model setting.

* Context menu option for changing type of shading group (building/site).

* New RDoc source code documentation for developers.



Bug Fixes for 1.0.0
-------------------

* Fixed problem with scrollbars appearing on all dialogs in SketchUp 7.

* Fixed bug with OutputControl:Table:Style object getting added twice when
  trying to run a simulation.

* Fixed bug with Location info not getting reset after hitting Apply.

* Fixed updating of Object Info window so that it does not always jump to
  the foreground.

* Fixed for bug where zone name changes were not being updated in Outliner
  window.



New Features for 0.9.5
----------------------

* Updated for EnergyPlus 3.0.

* Check for updates feature.



Bug Fixes for 0.9.5
-------------------

* Fix for two bugs with clockwise vertex order.

* Bug fix for a problem when editing a detached shading surface that would
  delete one of the commas between fields.

* Fix for bug with detached shading surfaces in relative coordinates.  New
  surfaces were throwing a ruby error.

* Better dialog layout and color matching for Windows XP themes.



New Features for 0.9.4
----------------------

* Updated for EnergyPlus 2.2.



Bug Fixes for 0.9.4
-------------------

* Vestigial input objects LEAD INPUT, END LEAD INPUT, SIMULATION DATA, and END
  SIMULATION DATA no longer generate errors if there are in an input file.

* Fix for progress dialog not closing after reading the data dictionary file
  (only in rare cases).

* Fixed a bug where the popup value for the Outside Boundary Object field was
  not being saved for SURFACE:HEATTRANSFER:SUB objects when edited in the
  Object Info window.

* Fixed a bug where entering a blank value for fields in the Object Info window
  resulted in losing the blank field (and its comma) in the text for the input
  object.

* Fixed a bug where text field values were not being saved in the Object Info
  window unless the user clicked somewhere else in the window before selecting
  a different object.



New Features for 0.9.3
----------------------

* Can set the Location object for the input file, including latitude, 
  longitude, elevation, and time zone.  Latitude, longitude, and time zone are
  also linked to the SketchUp location.

* All SurfaceGeometry object fields are honored, including coordinate system,
  surface starting vertex (e.g., UpperLeftCorner), and vertex order (e.g.,
  CounterClockwise).  Choice of coordinate system can be changed dynamically.

* Progress dialogs added for reading and drawing an input file.

* Error notification for the user when an internal plugin error is encountered.



Bug Fixes for 0.9.3
-------------------

* Input files using the relative coordinate system now draw correctly.

* Subsurface (e.g., window) constructions were not saving correctly.  This is
  fixed now.

* Bogus construction references are not automatically deleted from Object Info
  window anymore.

* Undo of erasing a zone group is fixed to work better.  But undo will only go
  one action back in time.

* Reduced (zero?) crashing due to copy-paste or cut-paste of surfaces.

* When editing a zone, if no surface is selected, the Object Info window shows
  the info for the zone object, not the building object as it did before.



Known Issues
------------

Missing Or Incomplete Features

* No way to edit or delete constructions and materials for surfaces. 

* No way to set the zone origin for a zone (only matters for relative 
  coordinate system). 

* No way to manipulate daylighting reference points. 


Unexpected Behaviors

* Admin privileges are required to run EnergyPlus simulations from within
  the plugin.

* Opening SKP files that have an associated IDF file can result in a set of
  duplicates surfaces that are slightly offset from the original surfaces.
  Use the Open and Save commands on the Plugins/OpenStudio menu instead.

* Attached shading surfaces (Shading:Zone:Detailed) often reference the
  wrong base surface.  This is harmless.

* Creating a new zone or shading group requires the user to double-click the 
  group to edit it instead of automatically opening for edit when the group is 
  placed. 

* During open of an input file, a subsurface (window or door) that shares more 
  than one edge with the base surface breaks the base surface into two and 
  leaves the subsurface stranded, not contained by either base surface. 

* During open of an input file, some surfaces will have thick lines between 
  them instead of thin.  Erasing the thick line deletes two edges instead of 
  one and erases both surfaces.  Work-around is to draw over the line with the 
  pencil tool so that the adjoining edges turn into a thin line.
  (ONLY IN SKETCHUP 6.)

* Deleting a base surface by erasing a shared edge with another base surface 
  does not update the subsurfaces of the deleted base surface the new base 
  surface.  Work-around is to change the base surface reference manually using 
  the Object Info window. 

* Input fields in the Object Info window do not validate.  It’s possible to put 
  in bad values. 

* Multiple selections don’t show up in the Object Info window, just the first of 
  the selected objects. 

* Total Exterior Surface Area and other values when a zone is selected in the 
  Object Info window can give incorrect results if the zone has been scaled 
  externally via the group. 

* It’s difficult to subdivide a floor into perimeter/core surfaces without 
  unintentionally creating a bunch of windows on the perimeter. 

* Different aspect ratios applied using the GeometryTransform object are not 
  honored.  

* Daylighting reference points are not transformed correctly if switching
  between coordinate systems. 


Crashes

* Random BugSplats when exiting SketchUp. 



Support
-------

We recognize that there are still bugs in OpenStudio.  SketchUp is a flexible
and dynamic program that allows the user to draw all kinds of geometry in
many different ways...we certainly haven’t been able to test every single one
of them.  We welcome your assistance in identifying bugs so that we can get
them fixed in the next version.  We also welcome any feedback on how we might
improve the plugin, feature requests, compliments, criticisms, etc.

For all bug reports, feedback, and questions about OpenStudio, please visit
the collaborative project website on SourceForge.net:

http://openstudio.sourceforge.net

The project website allows you to join the user support mailing list, browse
the list of known issues in the bug tracker, or post a new bug report.

If OpenStudio detects that an error has occurred, an "Error Alert" window will
appear.  Your first step for resolving the error should be to visit the
project website to check the bug tracker and user support mailing list to
determine if someone else has encountered the same problem.  If the issue has
already been reported, there is a good chance you will find a workaround
posted as well.


Reporting A Bug

If you think you have found an unreported bug, the next step is to send an
email to the user support mailing list.  You can help us the most if you
follow these suggestions:

* Describe the bug in your email message.  Tell us what you were doing when it
  happened, and if possible, describe the steps necessary to reproduce the
  problem.

* If the "Error Alert" window appeared, copy and paste the error message and
  backtrace into your email.

* Attach the EnergyPlus input file (.idf) and the SketchUp file (.skp) with
  your email.
 
We’ll try to respond to your email as quickly as possible.  Thanks for your help
and patience!

