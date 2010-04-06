model = Sketchup.active_model
entities = model.active_entities

# This is making a test face for the script, but we will want this to apply to the face within the Illuminance Map instance. Right now I made an extra group to lock it so users don't incorrectly scale it (by using move vs. scale).

pts = []
pts[0] = [0, 0, 39.370079]
pts[1] = [39.370079, 0, 39.370079]
pts[2] = [39.370079, 39.370079, 39.370079]
pts[3] = [0, 39.370079, 39.370079]
# Add the face to the entities in the model
face = entities.add_face pts

# set variables for number of grid points for x and y
xgrid = 5
ygrid = 5

material = model.materials[0]
pt_array = []

# 4 pairs of points
# 3d point from object
# then point from texture (in size based on size of material set in SU vs. pixel or inherant imagage size)

#origin
pt_array[0] = Geom::Point3d.new(0,0,0)
pt_array[1] = Geom::Point3d.new(0,0,0)

#x corner
pt_array[2] = Geom::Point3d.new(393.70079,0,0)
pt_array[3] = Geom::Point3d.new(xgrid,0,0)

# x&y corner
pt_array[4] = Geom::Point3d.new(393.70079,393.70079,0)
pt_array[5] = Geom::Point3d.new(xgrid,ygrid,0)

#x corner
pt_array[6] = Geom::Point3d.new(0,393.70079,0)
pt_array[7] = Geom::Point3d.new(0,ygrid,0)

# set texture position and scale
# if these materials "grid-front" and "grid-back" aren't in model this wont't work
# Dan right now my texture is set to 1 meter in SketchUp, but it seems to want inches fir tor the 3d points. Maybe the calculations woudl be easier if i reset the material to be 1" by 1" vs. 1 meter by 1 meter. Very easy change to make if it helps.

on_front = true
face.position_material "grid-front", pt_array, on_front
on_front = false
face.position_material "grid-back", pt_array, on_front
