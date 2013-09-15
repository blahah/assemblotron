require "biopsy"
require "logger"

module Assemblotron

  class Controller
  
    attr_accessor :global_opts
    attr_accessor :cmd_opts

    # Return a new Assemblotron
    def initialize
      @log = Logger.new(STDOUT)
      @log.level = Logger::INFO
      self.load_config
      self.init_settings
      @assemblers = []
      self.load_assemblers
    end # initialize

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
          @log.warn "config file malformed or empty"
          return
        end
        @config = config.deep_symbolize
      end
    end # parse_config

    # Discover and load available assemblers.
    #
    # Loads all assemblers provided by the program, and
    # then searches any directories listed in the config
    # file (+~/.assemblotron+) setting +assembler_dirs+.
    #
    # Directories listed in +assembler_dirs+ must contain:
    #
    # +definitions+::  Directory with one +.yml+ definition per assembler.
    #                  See the documentation for Definition.
    # +constructors+:: Directory with one +.rb+ file per assembler.
    #                  See the documentation for Constructor. 
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

    # Return an array of the names of available assemblers
    def assemblers
      @assemblers.map { |t| t.name } 
    end # assemblers

    def list_assemblers

    end # list_assemblers

    def run_options

    end # run_options

    def options_for_assembler assembler

    end # options_for_assembler

    def run cmd

    end # run

  end # Controller

end # Assemblotron