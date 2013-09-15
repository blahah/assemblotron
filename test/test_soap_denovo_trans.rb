require 'helper'

class TestSoapDenovoTrans < Test::Unit::TestCase

  context "SoapDenovoTrans constructor" do

    setup do
      @c = Assemblotron::Controller.new
      @c.init_settings
      @t = Biopsy::Target.new
      @t.load_by_name 'soap_denovo_trans'
      @s = SoapDenovoTrans.new
      @params = { 
        :readformat => 'fastq',
        :insertsize => '200',
        :l => 'l.fq',
        :r => 'r.fq',
        :path => 'SOAPdenovo-Trans',
        :memory => 12,
        :threads => 8,
        :out => 1,
      }
    end

    should "generate a valid config file" do
      valid = %Q{max_rd_len=20000
[LIB]
avg_ins=200
reverse_seq=0
asm_flags=3
rank=2
q1=l.fq
q2=r.fq
}
      @s.setup_soap(@params)
      assert_equal valid, File.open('soapdt.config').read
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
      expected = "SOAPdenovo-Trans all -s soapdt.config"
      expected += " -a 12 -o 1 -p 8 -K 1 -d 2 -F -M 9 -L 200"
      expected += " -e 6 -t 6 -G 50"
      assert_equal expected, @s.construct_command(@params)
    end

    should "automatically include defaults" do
      expected = "SOAPdenovo-Trans all -s soapdt.config"
      expected += " -a 12 -o 1 -p 8 -K 23 -d 0 -F -M 1"
      expected += " -L 100 -e 2 -t 5 -G 50"
      assert_equal expected, @s.construct_command(@params)
    end

  end # SoapDenovoTrans constructor context

end # TestSoapDenovoTrans