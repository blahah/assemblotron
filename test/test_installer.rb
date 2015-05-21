require 'helper'

class TestInstaller < Minitest::Test

  context 'Installer' do

    setup do
      @c = Assemblotron::Controller.new
      @c.init_settings
    end

    should 'expect a YAML set of download sources for an assembler' do
      assert false, 'not implemented'
    end

    should 'download the appropriate version for the host system' do
      assert false, 'not implemented'
    end

    should 'install missing assemblers and make them available in PATH' do
      assert false, 'not implemented'
    end

  end # context

end # TestInstaller
