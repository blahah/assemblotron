require 'helper'

class TestInstaller < Test::Unit::TestCase

  context 'Installer' do

    setup do
      @c = Assemblotron::Controller.new
      @c.init_settings
    end

    should 'expect a YAML set of download sources for an assembler' do

      assert_equal 1, 2
    end

    should 'download the appropriate version for the host system' do
      assert_equal 1, 2
    end

    should 'install missing assemblers and make them available in PATH' do
      assert_equal 1, 2
    end

  end # context

end # TestInstaller