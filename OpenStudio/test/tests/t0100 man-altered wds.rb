require 'test/unit'

module OpenStudio

  class T0100_Man_Altered_WDS < Test::Unit::TestCase

    def setup
      # top level setup
      OpenStudio::setup()

      # path to test file
      @path = $OpenStudio_TestPath + "testcases/t0100 man-altered  wds.idf"

      # open the test file
      Plugin.model_manager.close_input_file
      Plugin.model_manager.detach_input_file
      Plugin.model_manager.open_input_file(@path)
    end

    def teardown
      # close input file
      #Plugin.model_manager.close_input_file
      #Plugin.model_manager.detach_input_file

      # top level teardown
      OpenStudio::teardown()
    end
    
    def test_just_idf
    
      # read in idf without model manager
      input_file = InputFile.new(Plugin.data_dictionary)
      input_file.open(@path)
      assert(input_file)
      
      objects1 = input_file.objects
      objects2 = Plugin.model_manager.input_file.objects
      
      # should not have more objects
      assert_equal(objects1.length, objects2.length)
      
      # no objects should have changed. DLM note this may not ne true
      all_equal = true
      objects1.each_index do |i|
        if (objects1[i] != objects2[i])
          all_equal = false
          #puts "#{objects1[i]} does not equal #{objects2[i]}"
        end
      end
      assert(all_equal)
    end
    
    def test_only_one_zone

      # check model
      model = Sketchup.active_model
      assert(model)

      # check that input file is not nil
      input_file = Plugin.model_manager.input_file
      assert(input_file)

      # check that there is only one zone
      objects = input_file.find_objects_by_class_name("Zone")
      assert_equal(1, objects.length)
      assert_equal("zone 1", objects[0].name)

    end

    def test_load
puts "test_load"
      # check model
      model = Sketchup.active_model
      assert(model)

      # check that input file is not nil
      assert(Plugin.model_manager.input_file)

      # check that model manager is not nill
      assert(Plugin.model_manager.model_interface)
      
    end
    
    def test_load_part2
puts "test_load_part2"
      # check model
      model = Sketchup.active_model
      assert(model)

      # check that input file is not nil
      assert(Plugin.model_manager.input_file)

      # check that model manager is not nill
      assert(Plugin.model_manager.model_interface)
    
    
    end

  end

  # add tests to global suite
  $OpenStudio_TestSuite << T0100_Man_Altered_WDS.suite

end