# add std ruby lib to path
$:.insert(0, OpenStudio::Plugin.dir + "/stdruby")

# require pathname and unit test from standard lib
# make sure we get these versions as modified versions are floating around in SU
require OpenStudio::Plugin.dir + '/stdruby/pathname'
require OpenStudio::Plugin.dir + '/stdruby/test/unit'
require OpenStudio::Plugin.dir + '/stdruby/test/unit/testsuite'
require OpenStudio::Plugin.dir + '/stdruby/test/unit/ui/console/testrunner'

# remove std ruby lib from path
$:.delete_at(0)

module OpenStudio

  # down selection for tests, based on file name, this could be improved
  # example: $OpenStudio_TestFilter = /NoWindows*/

  # path to test directory
  $OpenStudio_TestPath = Pathname.new(File.dirname(__FILE__))

  # define a module function to setup before each test
  def OpenStudio.setup

    # set preference to do everything in SI

    # set preference to erase entities on close
    Plugin.write_pref("Erase Entities", true)
  end


  # define a module function to clean up after each test
  def OpenStudio.teardown
    # common teardown
  end

  # initialize OpenStudio TestSuite
  $OpenStudio_TestSuite = Test::Unit::TestSuite.new("OpenStudio Test Suite")

  # load in test files, each test concatenates its TestCases to $OpenStudio_TestSuite
  Dir.glob($OpenStudio_TestPath + "tests/**/*.rb").each do |test|

    # skip filtered tests
    if not $OpenStudio_TestFilter.nil?
      if not $OpenStudio_TestFilter.match(test)
        next
      end
    end

    load("#{test}")
  end

  # output file path
  output_path = Pathname.new(File.dirname(__FILE__)) + "OpenStudio.test.out"

  # run the tests and send results to file
  File.open(output_path, "w") do |file|
    Test::Unit::UI::Console::TestRunner.new($OpenStudio_TestSuite, Test::Unit::UI::VERBOSE, file).start()
  end

end