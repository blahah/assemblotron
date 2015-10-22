module Assemblotron

  # Co-ordinates the entire assembly optimisation process
  #
  # @!attribute [r] options
  #   @return [Hash] the global options
  # @!attribute [r] assembler_options
  #   @return [Hash] the assembler-specific options
  class Controller

    attr_accessor :options

    # Creates a new Controller
    #
    # @return [Controller] the Controller
    def initialize options
      self.init_settings
      @options = process_options options
      @assemblerman = AssemblerManager.new @options
    end # initialize

    # Cleanup and validity checking of global options
    def process_options options
      options = options.clone
      [:left, :right].each do |key|
        if options.key?(key) && !(options[key].nil?)
          options[key] = File.expand_path options[key]
        end
      end
      options
    end

    # Runs the program
    def run
      if @options[:list_assemblers]
        puts @assemblerman.list_assemblers
        return
      elsif @options[:install_assemblers]
        @assemblerman.install_assemblers(@options[:install_assemblers])
        return
      end

      if (@options[:left].nil? || @options[:right].nil?)
        logger.error "Reads must be provided with --left and --right"
        logger.error "Try --help for command-line help"
        exit(1)
      end

      unless (@options[:timelimit].nil?)
        logger.info "Time limit set to #{@options[:timelimit]}"
      end

      subsample_input

      res = @assemblerman.run_all_assemblers @options

      merge_assemblies res

    end

    # Create a header containing the program name
    # and the installed version, for inclusion in
    # command-line logging and help.
    #
    # @return [String] the header text
    def self.header
      "Assemblotron v#{VERSION::STRING.dup}"
    end

    # Initialise the Biopsy settings with defaults,
    # setting target and objectiv directories to those
    # provided with Assemblotron
    def init_settings
      s = Biopsy::Settings.instance
      s.set_defaults
      libdir = File.dirname(__FILE__)
      s.target_dir = [File.join(libdir, 'assemblers/')]
      s.objectives_dir = [File.join(libdir, 'objectives/')]
      logger.debug "initialised Biopsy settings"
    end

    # Write out metadata from the optimisation run
    def write_metadata
      File.open(@options[:output_parameters], 'wb') do |f|
        f.write(JSON.pretty_generate(res))
      end
    end

    # Run the subsampler on the input reads, storing
    # the paths to the samples in the assembler_options
    # hash.
    def subsample_input

      if @options[:skip_subsample]
        logger.info "Skipping subsample step (--skip-subsample is on)"
        @options[:left_subset] = @options[:left]
        @options[:right_subset] = @options[:right]
        return
      end

      logger.info "Subsampling reads"

      l = @options[:left]
      r = @options[:right]
      size = @options[:subsample_size]

      s = Sample.new(l, r)
      ls, rs = s.subsample size

      @options[:left_subset] = ls
      @options[:right_subset] = rs

    end

    # Merge the final assemblies
    def merge_assemblies res

      l = @options[:left]
      r = @options[:right]

      transfuse = Transfuse::Transfuse.new(opts.threads, false)
      assemblies = res.each_value.map { |assembler| assember[:final] }
      scores = transfuse.transrate(assemblies, l, r)
      filtered = transfuse.filter(assemblies, scores)
      cat = transfuse.concatenate filtered
      transfuse.load_fasta cat
      clusters = transfuse.cluster cat
      best = transfuse.select_contigs(clusters, scores)
      transfuse.output_contigs(best, cat, opts.output)

    end

  end # Controller

end
