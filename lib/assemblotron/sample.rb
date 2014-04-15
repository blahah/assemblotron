module Assemblotron

  class Sample

    # Return a new Sample with left and right reads
    def initialize(left, right)
      @left = left
      @right = right
    end

    # Take a uniform random subsample of n reads from
    # each of the input FASTQ files @left and @right
    # using reservoir sampling.
    def subsample(n, seed = 1337)
      rng = Random.new seed
      n = n.to_f
      count = 1

      l = File.open(@left).each_line.each_slice 4
      r = File.open(@right).each_line.each_slice 4

      reservoir = []
      first = true
      l.zip(r).each do |lrec, rrec|
        if count <= n
          # fill the reservoir with the first
          # n read pairs
          reservoir << [lrec, rrec]
        else
          # select this read with probability n / m
          if rng.rand < n / count
            # replace a random item in the reservoir
            i = rng.rand(n)
            reservoir[i] = [lrec, rrec]
          end
        end
        count += 1
      end

      # write out the reservoir reads
      ldir = File.dirname(@left)
      loutfile = File.join(ldir, "subset.#{File.basename @left}")
      lout = File.open(loutfile, 'wb')
      rdir = File.dirname(@right)
      routfile = File.join(rdir, "subset.#{File.basename @right}")
      rout = File.open(routfile, 'wb')
      reservoir.each do |lrec, rrec|
        lout.puts lrec
        rout.puts rrec
      end

      lout.close
      rout.close

      [loutfile, routfile]
    end

  end

end
