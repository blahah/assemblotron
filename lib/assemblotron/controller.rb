module Assemblotron

  # Co-ordinates the entire assembly optimisation process
  #
  # @!attribute [r] global_opts
  #   @return [Hash] the global options
  # @!attribute [r] assembler_opts
  #   @return [Hash] the assembler-specific options
  class Controller

    attr_accessor :global_opts
    attr_accessor :assembler_opts

    # Creates a new Controller
    #
    # @return [Controller] the Controller
    def initialize
      self.load_config
      self.init_settings
      @assemblerman = AssemblerManager.new
    end # initialize

    # Runs the program
    def run
      @assemblerman.list_assemblers if @global_opts[:list_assemblers]
    end

    # Creates a header containing the program name
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
    end # init_settings

    # Load global configuration from the config file at
    # +~/.assemblotron+, if it exists.
    def load_config
      config_file = File.join(Dir.home, ".assemblotron")
      if File.exists? config_file
        logger.debug "config file found at #{config_file}"
        config = YAML::load_file(config_file)
        if config.nil?
          logger.warn 'config file malformed or empty'
          return
        end
        @config = config.deep_symbolize
      end
    end # parse_config

    # Run the subsampler on the input reads, storing
    # the paths to the samples in the assembler_opts
    # hash.
    def subsample_input
      l = @assembler_opts[:left]
      r = @assembler_opts[:right]
      size = @global_opts[:subsample_size]

      s = Sample.new(l, r)
      ls, rs = s.subsample size

      @assembler_opts[:left_subset] = ls
      @assembler_opts[:right_subset] = rs
    end

  end # Controller

end
