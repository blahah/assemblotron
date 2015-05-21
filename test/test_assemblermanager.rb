require 'helper'
require 'trollop'

class TestAssemblerManager < Minitest::Test

  context 'AssemblerManager' do

    setup do
      @am = Assemblotron::AssemblerManager.new
    end

    should 'load the installed assemblers' do
      test_dir = File.dirname(__FILE__)
      assembler_dir = File.join(test_dir, '../lib/assemblotron/assemblers')
      assembler_dir = File.expand_path(assembler_dir)
      assembler_count = Dir[File.join(assembler_dir, "*.yml")].size
      assert assembler_count > 0,
             'there must be at least one definition in the assemblers dir'
      @am.load_assemblers
      assert @am.assemblers.size > 0,
             'there must be at least one assembler loaded'
      assert assembler_count <= @am.assemblers.size,
             'there must be at least as many loaded' +
             ' names as assembler definitions'
    end

    should 'list the installed assemblers' do
      capture_stdout do
        @am.load_assemblers
        msg = @am.list_assemblers
        @am.assemblers.each do |a|
          assert msg =~ %r{#{a}},
                 "assembler #{a} must be listed in list command output"
        end
      end
    end

    should 'select installed assemblers by name' do
      ['SoapDenovoTrans', 'sdt'].each do |assembler|
        t = nil
        t = @am.get_assembler(assembler)
        assert_equal Assemblotron::AssemblotronTarget, t.class,
                     'get_assembler must return a Assemblotron::AssemblotronTarget'
        assert (t.name == assembler || t.shortname == assembler),
               'get_assembler must return the correct target'

      end
    end

    should 'complain helpfully if requested assembler is not installed' do
      @am.load_assemblers
      assert_raises RuntimeError do
        @am.get_assembler 'not_a_real_assembler'
      end
    end

    should 'generate parser for installed assembler' do
      ['sdt', 'SoapDenovoTrans'].each do |assembler|
        o = nil
        o = @am.parser_for_assembler assembler
        assert_equal Trollop::Parser, o.class
      end
    end

  end # Assemblers

end
