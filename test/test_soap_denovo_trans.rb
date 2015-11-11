require 'helper'
require 'tmpdir'

class TestSoapDenovoTrans < Minitest::Test

  context "Constructor" do

    setup do
      @c = Assemblotron::Controller.new({})
      @c.init_settings
      @t = Biopsy::Target.new
      @t.load_by_name 'soap_denovo_trans'
      @s = SoapDenovoTrans.new
      @params = {
        :readformat => 'fastq',
        :insert_size => '200',
        :left => 'l.fq',
        :right => 'r.fq',
        :memory => 12,
        :threads => 8,
        :out => 'out',
        :config => 'soapdt.config'
      }
      @sdt_path = `which SOAPdenovo-Trans-127mer`.strip
    end

    should "construct a valid command" do
      params = {
        :K => 1,
        :d => 2,
        :M => 9,
        :F => true,
        :L => 200,
        :u => false,
        :e => 6,
        :t => 6
      }
      @params.merge! params
      expected = "#{@sdt_path} all -s soapdt.config"
      expected += " -a 12 -o out -p 8 -K 1 -d 2 -F -M 9 -L 200"
      expected += " -e 6 -t 6 -G 50"
      assert_equal expected, @s.construct_command(@params, 'soapdt.config')
    end

    should "automatically include defaults" do
      expected = "#{@sdt_path} all -s soapdt.config"
      expected += " -a 12 -o out -p 8 -K 23 -d 0 -F -M 1"
      expected += " -L 100 -e 2 -t 5 -G 50"
      assert_equal expected, @s.construct_command(@params, 'soapdt.config')
    end

    should "create config file" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir tmpdir do
          filename = @s.create_config @params
          assert File.exist?(filename)
          config = File.open(filename, "rb").read
          expected = "max_rd_len=200\n[LIB]\navg_ins=200\nreverse_seq=0\n"
          expected << "asm_flags=3\nrd_len_cutoff=150\nmap_len=50\n"
          expected << "q1=l.fq\nq2=r.fq\n"
          assert_equal expected, config, "config"
        end
      end
    end

  end # SoapDenovoTrans constructor context

end # TestSoapDenovoTrans
