require 'test/unit'

module OpenStudio

  class BasicZone_NoWindowDrawn < Test::Unit::TestCase

    def setup
      # top level setup
      OpenStudio::setup()

      # path to test file
      path = $OpenStudio_TestPath + "testcases/BasicZone.idf"

      # open the test file
      Plugin.model_manager.close_input_file
      Plugin.model_manager.detach_input_file
      Plugin.model_manager.open_input_file(path)
    end

    def teardown
      # close input file
      #Plugin.model_manager.close_input_file
      #Plugin.model_manager.detach_input_file

      # top level teardown
      OpenStudio::teardown()
    end

    def test_load

      # check model
      model = Sketchup.active_model
      assert(model)

      # check that input file is not nil
      assert(Plugin.model_manager.input_file)

      # check that model manager is not nill
      assert(Plugin.model_manager.model_interface)

      # find the test zone
      zone = Plugin.model_manager.zones[0]
      assert(zone)
      assert_equal("Zone1", zone.input_object.name)

      # should be no windows
      subsurfaces = Plugin.model_manager.input_file.find_objects_by_class_name("FenestrationSurface:Detailed")
      assert(subsurfaces.empty?)

      # add a window
      pts = []
      pts[0] = [1.5, -1, 1.5]
      pts[1] = [1.5, -1, 0.5]
      pts[2] = [4.5, -1, 0.5]
      pts[3] = [4.5, -1, 1.5]

      # Add the face to the zone
      face = zone.entity.entities.add_face(pts)
      assert(face)

      # check that a new window was created
      subsurfaces = Plugin.model_manager.input_file.find_objects_by_class_name("FenestrationSurface:Detailed")
      assert(subsurfaces.length() == 1)
      # assert base surface is right, etc

    end

  end

  # add tests to global suite
  $OpenStudio_TestSuite << BasicZone_NoWindowDrawn.suite

end