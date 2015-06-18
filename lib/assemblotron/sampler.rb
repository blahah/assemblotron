module Assemblotron

  class Sampler

    def initalize

      # check seqtk is installed - install it if not
      gem_dir = Gem.loaded_specs['assemblotron'].full_gem_path
      gem_deps = File.join(gem_dir, 'deps.yaml')
      Bindeps.require gem_deps

      missing = Bindeps.missing gem_deps
      unless missing.empty?
        raise StandardError.new('seqtk was not found and ' +
                                'could not be installed')
      end

      @bin = which('graphsample').first

    end

    def run cmd

      task = Cmd.new "#{@bin} #{cmd}"
      task.run

      unless task.status.success?
        msg = "graphsample command #{cmd} failed\n"
        msg << "stdout:\n"
        msg << task.stdout
        msg << "\nstderr:\n"
        msg << task.stderr
        raise StandardError.new(msg)
      end

    end

    def sample_graph(left, right, rate, seed, diginorm=false)
      prefix = "#{seed}.#{rate}"
      cmd = "--left #{left} --right #{right} --output #{prefix}"
      cmd << " -k 21 --rate #{rate} --seed #{seed} #{diginormstr}"

      run cmd

      ls = "#{prefix}.#{File.basename left}")
      rs = "#{prefix}.#{File.basename right}")

      [ls, rs]
    end

    def diginormstr diginorm
      diginorm ? " --diginorm" : ""
    end

    def sample_stream(left, right, size, seed)
      ldir = File.dirname left
      ls = File.join(ldir, "subset.#{size}.#{seed}.#{File.basename left}")
      rdir = File.dirname rirght
      rs = File.join(rdir, "subset.#{size}.#{seed}.#{File.basename right}")

      s = Seqtk::Seqtk.new
      s.sample(left, ls, size, seed)
      s.sample(right, rs, size, seed)

      [ls, rs]
    end

  end

end
