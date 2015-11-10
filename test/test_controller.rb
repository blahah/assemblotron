require 'helper'
require 'trollop'

class TestController < Minitest::Test

  context 'Settings' do

    setup do
      @c = Assemblotron::Controller.new({})
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

    should "expand read file paths" do
      options = {
        :left => "left.fq",
        :right => "right.fq"
      }
      dir = Dir.pwd
      c = Assemblotron::Controller.new(options)
      assert_equal File.join(dir, options[:left]), c.options[:left]
      assert_equal File.join(dir, options[:right]), c.options[:right]
    end

  end # Settings

end # TestInstaller
