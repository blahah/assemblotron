module Assemblotron

  class Simulator < Biopsy::Target


    def setup infile

      setup_biopsy

      load_simulation_data infile

      generate_parameters transpose_simdata

    end # setup_target

    def setup_biopsy
      s = Biopsy::Settings.instance
      s.set_defaults
      libdir = File.dirname(__FILE__)
      s.target_dir = [File.join(libdir, 'simulator/')]
      s.objectives_dir = [File.join(libdir, 'simulator/')]
      s.no_tempdirs = true
      @output = {}
      @name = 'simulator'
    end

    # load pre-calculated data from an assemblotron sweep
    def load_simulation_data infile
      @simdata = {}
      keys = nil
      CSV.foreach infile do |line|
        if keys.nil?
          *keys, score = line
        else
          *params, score = line
          params = Hash[keys.zip params]
          @simdata[params] = score
        end
      end
    end

    # turn the array of hashes containing simdata params into
    # a hash of arrays
    def transpose_simdata
      keys = @simdata.keys.first.keys
      valuehashes = (1..keys.length).map { || {} }
      t = Hash[keys.zip valuehashes]
      @simdata.keys.each do |params|
        params.each_pair do |k, v|
          t[k][v] = true
        end
      end
      t.keys.each do |key|
        unique = t[key].keys
        t[key] = {
          :values => unique,
          :opt => true,
          :type => unique.first.is_a?(String) ? 'string' : 'integer'
        }
      end
      t
    end

    def run params
      { :simdata => @simdata, :params => params }
    end

  end

end # Assemblotron
