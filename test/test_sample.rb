require 'helper'

class TestSample < Test::Unit::TestCase

  context 'Sample' do

    setup do
      datadir = File.join(File.dirname(__FILE__), 'data')
      datadir = File.absolute_path datadir
      l = File.join(datadir, 'thousand_reads_l.fq') 
      r = File.join(datadir, 'thousand_reads_r.fq')
      @sample = Assemblotron::Sample.new(l, r)
    end

    should 'subsample the specified number of reads' do
      ns = [50, 100, 200, 500]
      ns.each do |n|
        l, r = @sample.subsample n
        actual_n_l = `wc -l #{l}`.to_i / 4
        actual_n_r = `wc -l #{r}`.to_i / 4
        assert_equal n, actual_n_l, "left read subsample size should be #{n}"
        assert_equal n, actual_n_r, "right read subsample size should be #{n}"
      end
    end

  end # context

end # TestSample