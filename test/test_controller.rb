require 'helper'
require 'trollop'

class TestController < Test::Unit::TestCase

  context 'Settings' do

    setup do
      @c = Assemblotron::Controller.new
    end

    should 'produce an accurate version header' do
      version = "v#{Assemblotron::VERSION::MAJOR}\." +
                "#{Assemblotron::VERSION::MINOR}\." +
                "#{Assemblotron::VERSION::PATCH}"
      assert Assemblotron::Controller::header =~ %r{#{version}}
    end

    should 'intitialise Biopsy settings from default directories' do
      @c.init_settings
      libdir = File.dirname(__FILE__)
      expect_target_dir = File.join(libdir, '../lib/assemblotron/assemblers/')
      expect_objectives_dir = File.join(libdir,
                                        '../lib/assemblotron/objectives/')
      given_target_dir = Biopsy::Settings.instance.target_dir.first
      given_objectives_dir = Biopsy::Settings.instance.objectives_dir.first
      assert_equal File.expand_path(expect_target_dir),
                   File.expand_path(given_target_dir),
                   'target dir must be correctly loaded'
      assert_equal File.expand_path(expect_objectives_dir),
                   File.expand_path(given_objectives_dir),
                   'objectives dir must be correctly loaded'
    end

    should 'load global config' do
      assert false, 'TODO: should config be removed?'
    end

  end # Settings

  context 'Running' do

    should 'be able to subsample input reads' do
      assert false, 'not implemented'
    end

    should 'run a final assembly with full reads and optimal parameters' do
      assert false, 'not implemented'
    end

    should 'optimise the parameters of any valid assembler' do
      assert false, 'not implemented'
    end

  end # Running

end # TestInstaller
