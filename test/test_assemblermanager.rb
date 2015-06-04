require 'helper'
require 'trollop'

class TestAssemblerManager < Minitest::Test

  context 'Setup' do

    setup do
      @c = Assemblotron::Controller.new({})
      @am = Assemblotron::AssemblerManager.new({})
    end

    should 'load the installed assemblers' do
      test_dir = File.dirname(__FILE__)
      assembler_dir = File.join(test_dir, '../lib/assemblotron/assemblers')
      assembler_dir = File.expand_path(assembler_dir)
      assembler_count = Dir[File.join(assembler_dir, "*.yml")].size
      assert assembler_count > 0,
             'there must be at least one definition in the assemblers dir'
      @am.load_assemblers
      assert @am.assembler_names.size > 0,
             'there must be at least one assembler loaded'
      assert assembler_count <= @am.assembler_names.size,
             'there must be at least as many loaded' +
             ' names as assembler definitions'
    end

    should 'list the installed assemblers' do
      @am.load_assemblers
      msg = @am.list_assemblers
      @am.assembler_names.each do |a|
        assert msg =~ %r{#{a}},
               "assembler #{a} must be listed in list command output"
      end
    end

    should 'select installed assemblers by name' do
      ['SoapDenovoTrans', 'sdt'].each do |assembler|
        t = nil
        t = @am.get_assembler(assembler)
        assert_equal Assemblotron::Assembler, t.class,
                     'get_assembler must return a Assemblotron::Assembler'
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

    should 'run a specified assembler' do
      test_dir = File.dirname(__FILE__)
      left = File.join(test_dir, 'data', 'reads_1.fastq')
      right = File.join(test_dir, 'data', 'reads_2.fastq')
      am = Assemblotron::AssemblerManager.new({
        :left_subset => left,
        :right_subset => right,
        :threads => 4,
        :insert_size => 200
      })
      # am.run_assembler am.get_assembler('idba')
    end

    should 'install a specified assembler' do
      @am.assemblers_uninst.each do |assembler|
        Dir.mktmpdir do |dir|
          @am.install_assemblers(assembler.name, dir)
          bin = assembler.bindeps[:binaries].first
          assert File.exist?(File.join(dir, 'bin', bin)),
            "#{bin} should be in #{dir}"
        end
      end
    end

  end # Setup

end
