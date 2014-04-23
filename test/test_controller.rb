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

  context 'Assemblers' do

    setup do
      @c = Assemblotron::Controller.new
    end

    should 'load the installed assemblers' do
      test_dir = File.dirname(__FILE__)
      assembler_dir = File.join(test_dir, '../lib/assemblotron/assemblers')
      assembler_dir = File.expand_path(assembler_dir)
      assembler_count = Dir[File.join(assembler_dir, "*.yml")].size
      assert assembler_count > 0,
             'there must be at least one definition in the assemblers dir'
      @c.load_assemblers
      assert @c.assemblers.size > 0,
             'there must be at least one assembler loaded'
      assert assembler_count <= @c.assemblers.size,
             'there must be at least as many loaded' +
             ' names as assembler definitions'
    end

    should 'list the installed assemblers' do
      @c.load_assemblers
      msg = @c.list_assemblers
      @c.assemblers.each do |a|
        assert msg =~ %r{#{a}},
               "assembler #{a} must be listed in list command output"
      end
    end

    should 'select installed assemblers by name' do
      ['SoapDenovoTrans', 'sdt'].each do |assembler|
        t = nil
        assert_nothing_raised { t = @c.get_assembler(assembler) }
        assert_equal Biopsy::Target, t.class,
                     'get_assembler must return a Biopsy::Target'
        assert (t.name == assembler || t.shortname == assembler),
               'get_assembler must return the correct target'

      end
    end

    should 'complain helpfully if requested assembler is not installed' do
      @c.load_assemblers
      assert_raise RuntimeError do
        @c.get_assembler 'not_a_real_assembler'
      end
    end

    should 'convert type descriptions to Classes' do
      assert_equal String, Assemblotron::Controller.class_from_type('str')
      assert_equal String, Assemblotron::Controller.class_from_type('string')
      assert_equal Integer, Assemblotron::Controller.class_from_type('int')
      assert_equal Integer, Assemblotron::Controller.class_from_type('integer')
      assert_equal Float, Assemblotron::Controller.class_from_type('float')
      assert_equal nil, Assemblotron::Controller.class_from_type('notarealtype')
    end

    should 'generates parser for installed assembler' do
      ['sdt', 'SoapDenovoTrans'].each do |assembler|
        o = nil
        assert_nothing_raised { o = @c.parser_for_assembler assembler }
        assert_equal Trollop::Parser, o.class
      end
    end

  end # Assemblers

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