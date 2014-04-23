require 'biopsy'
require 'logger'
require 'transrate'
require 'assemblotron/version'
require 'assemblotron/sample'
require 'pp'
require 'json'

module Assemblotron

  include Transrate


  class Controller
  
    attr_accessor :global_opts
    attr_accessor :assembler_opts

    # Return a new Assemblotron
    def initialize
      @log = Logger.new(STDOUT)
      @log.level = Logger::INFO
      self.load_config
      self.init_settings
      @assemblers = []
      self.load_assemblers
    end # initialize

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
      a = []
      @assemblers.each do |t|
        a << t.name
        a << t.shortname if t.shortname
      end
      a
    end # assemblers

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

    def get_assembler assembler
      ret = @assemblers.find do |a|
        a.name == assembler || 
        a.shortname == assembler
      end
      raise "couldn't find assembler #{assembler}" if ret.nil?
      ret
    end

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

    def subsample_input
      l = @assembler_opts[:left]
      r = @assembler_opts[:right]
      size = @global_opts[:subsample_size]

      s = Sample.new(l, r)
      ls, rs = s.subsample size
 
      @assembler_opts[:left_subset] = ls
      @assembler_opts[:right_subset] = rs
    end

    def final_assembly assembler, result
      Dir.mkdir('final_assembly')
      Dir.chdir('final_assembly') do
        assembler.run result
      end
    end

    def run assembler
      # subsampling
      if @global_opts[:skip_subsample]
        @assembler_opts[:left_subset] = assembler_opts[:left]
        @assembler_opts[:right_subset] = assembler_opts[:right]
      else
        subsample_input
      end

      # load reference and create ublast DB
      @assembler_opts[:reference] = Transrate::Assembly.new(@assembler_opts[:reference])
      ra = Transrate::ReciprocalAnnotation.new(@assembler_opts[:reference], @assembler_opts[:reference])
      ra.make_reference_db

      # setup the assembler
      a = self.get_assembler assembler
      a.setup_optim(@global_opts, @assembler_opts)

      # run the optimisation
      e = Biopsy::Experiment.new(a, options: @assembler_opts, threads: @global_opts[:threads])
      res = e.run

      # write out the result
      File.open(@global_opts[:output_parameters], 'wb') do |f|
        f.write(JSON.pretty_generate(res))
      end

      # run the final assembly
      a.setup_final(@global_opts, @assembler_opts)
      unless @global_opts[:skip_final]
        final_assembly a, res
      end
    end # run

  end # Controller

end # Assemblotron
