require 'biopsy'
require 'logger'
require 'transrate'
require 'assemblotron/version'
require 'assemblotron/sample'
require 'pp'
require 'json'

# An automated transcriptome assembly optimiser.
#
# Assemblotron takes a random subset of your input
# reads and uses the subset to optimise the settings
# of *any* assembler, then runs the assembler with 
# the full set of reads and the optimal settings.
module Assemblotron

  include Transrate

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
      @log = Logger.new(STDOUT)
      @log.level = Logger::INFO
      self.load_config
      self.init_settings
      @assemblers = []
      self.load_assemblers
    end # initialize

    # Creates a header containing the program name
    # and the installed version, for inclusion in 
    # command-line logging and help.
    #
    # @return [String] the header text
    def self.header
      "Assemblotron v#{VERSION::STRING.dup}"
    end

    # Initialise the Biopsy settings
    def init_settings
      s = Biopsy::Settings.instance
      s.set_defaults
      libdir = File.dirname(__FILE__)
      s.target_dir = [File.join(libdir, 'assemblotron/assemblers/')]
      s.objectives_dir = [File.join(libdir, 'assemblotron/objectives/')]
      @log.debug "initialised Biopsy settings"
    end # init_settings

    # Load global configuration from the config file at
    # +~/.assemblotron+, if it exists.
    def load_config
      config_file = File.join(Dir.home, ".assemblotron")
      if File.exists? config_file
        @log.debug "config file found at #{config_file}"
        config = YAML::load_file(config_file)
        if config.nil?
          @log.warn 'config file malformed or empty'
          return
        end
        @config = config.deep_symbolize
      end
    end # parse_config

    # Discover and load available assemblers.
    #
    # Loads all assemblers included with assemblotron,
    # then searches any directories listed in the config
    # file (+~/.assemblotron+) setting +assembler_dirs+ and
    # loads any assembler definitions found.
    #
    # Directories listed in +assembler_dirs+ must contain
    # one +.yml+ definition and one +.rb+ constructor per
    # assembler (see AssemblerDefinition).
    def load_assemblers
      Biopsy::Settings.instance.target_dir.each do |dir|
        Dir.chdir dir do
          Dir['*.yml'].each do |file|
            name = File.basename(file, '.yml')
            target = Biopsy::Target.new
            target.load_by_name name
            @assemblers << target
          end
        end
      end
    end # load_assemblers

    # Collect all valid names for available assemblers
    #
    # @return [Array<String>] names and shortnames (if
    #          applicable) for available assemblers.
    def assemblers
      a = []
      @assemblers.each do |t|
        a << t.name
        a << t.shortname if t.shortname
      end
      a
    end # assemblers

    # Produce a help message listing installed assemblers.
    #
    # @return [String] the help message.
    def list_assemblers
      str = Controller.header
      str << <<-EOS

Available assemblers are listed below.
Shortnames are shown in brackets if available.

Usage:
atron [global options] <assembler> [assembler options]

Assemblers:
EOS
      @assemblers.each do |a| 
        p = " - #{a.name}"
        p += " (#{a.shortname})" if a.respond_to? :shortname
        str << p
      end
      str
    end # list_assemblers

    # Generate an argument parser for the specified assembler
    # by extracting the parameters that are not intended to be
    # optimised from the assembler definition.
    #
    # @param assembler [String] assembler name or shortname
    # @return [Trollop::Parser] the argument parser
    def parser_for_assembler assembler
      a = self.get_assembler assembler
      parser = Trollop::Parser.new do
      banner <<-EOS
#{Controller.header}

Options for assembler #{assembler}
EOS
        opt :reference, "Path to reference proteome file in FASTA format",
             :type => String,
             :required => true
        a.options.each_pair do |param, opts|
          opt param, 
              opts[:desc], 
              :type => Controller.class_from_type(opts[:type])
        end
      end
    end # options_for_assembler

    # Given the name of an assembler, get the loaded assembler
    # ready for optimisation.
    #
    # @param assembler [String] assembler name or shortname
    # @return [Biopsy::Target] the loaded assembler
    def get_assembler assembler
      ret = @assemblers.find do |a|
        a.name == assembler || a.shortname == assembler
      end
      raise "couldn't find assembler #{assembler}" if ret.nil?
      ret
    end

    # Given the name of a type, return its class
    #
    # @param [String] type
    # @return [Class] the class corresponding to the type
    def self.class_from_type type
      case type
      when 'str'
        String
      when 'string'
        String
      when 'int'
        Integer
      when 'integer'
        Integer
      when 'float'
        Float
      end
    end

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

    # Run the final assembly using the specified assembler
    # and the optimal set of parameters.
    #
    # @param assembler [Biopsy::Target] the assembler
    # @param result [Hash] the optimal set of parameters 
    #   as chosen by the optimisation algorithm
    def final_assembly assembler, result
      Dir.mkdir('final_assembly')
      Dir.chdir('final_assembly') do
        assembler.run result
      end
    end

    # Run the entire Assemblotron process using the named
    # assembler using the options stored in #global_opts and
    # #assembler_opts.
    #
    # @param [String] assembler name or shortname
    def run assembler
      # subsampling
      if @global_opts[:skip_subsample]
        @assembler_opts[:left_subset] = assembler_opts[:left]
        @assembler_opts[:right_subset] = assembler_opts[:right]
      else
        subsample_input
      end

      # load reference and create ublast DB
      @assembler_opts[:reference] = 
        Transrate::Assembly.new(@assembler_opts[:reference])
      ra = Transrate::ReciprocalAnnotation.new(@assembler_opts[:reference],
                                               @assembler_opts[:reference])
      ra.make_reference_db

      # setup the assembler
      a = self.get_assembler assembler
      a.setup_optim(@global_opts, @assembler_opts)
      start = nil
      algorithm = nil
      if @global_opts[:optimiser] == 'tabu'
        algorithm = Biopsy::TabuSearch.new(a.parameters)
      elsif @global_opts[:optimiser] == 'sweeper'
        algorithm = Biopsy::ParameterSweeper.new(a.parameters)
      else
        raise NotImplementedError, "please select either tabu or\                                                     
         sweeper as the optimiser"
      end

      e = Biopsy::Experiment.new(a, @assembler_opts,
                                 @global_opts[:threads],
                                 start,
                                 algorithm,
                                 @global_opts[:verbosity].to_sym)

      res = e.run

      # write out the result
      File.open(@global_opts[:output_parameters], 'wb') do |f|
        f.write(JSON.pretty_generate(res))
      end

      # run the final assembly
      a.setup_final(@global_opts, @assembler_opts)
      final_assembly a, res unless @global_opts[:skip_final]

    end # run

  end # Controller

end # Assemblotron
