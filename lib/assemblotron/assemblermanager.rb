module Assemblotron

  class AssemblotronTarget < Biopsy::Target

    attr_accessor :binaries, :systems

    # store the values in +:config+, checking they are valid
    def store_config config
      logger.error("Definition for #{config[:name]} must specify required binaries") unless config.key?(:binaries)
      @binaries = config[:binaries]
      logger.error("Definition for #{config[:name]} must specify supported systems") unless config.key?(:systems)
      @systems = config[:systems]
      super config
    end

  end

  class System

    require 'rbconfig'

    def self.os
      (
        host_os = RbConfig::CONFIG['host_os']
        case host_os
        when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
          :windows
        when /darwin|mac os/
          :macosx
        when /linux/
          :linux
        when /solaris|bsd/
          :unix
        else
          raise UnsupportedSystemError,
                "can't install #{@name}, unknown os: #{host_os.inspect}"
        end
      )
    end

    def self.arch
      Gem::Platform.local.cpu == 'x86_64' ? '64bit' : '32bit'
    end

  end

  class AssemblerManager

    def initialize
      @assemblers = []
      load_assemblers
    end

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
            target = AssemblotronTarget.new
            target.load_by_name name
            sysmatch = target.systems.any? { |s| System.os == s.to_sym }
            unless sysmatch
              logger.info "Assembler #{target.name} is not available for this operating system"
              next
            end
            bin_paths = target.binaries.map { |bin| Which.which bin }
            missing_bin = bin_paths.any? { |path| path.nil? }
            if missing_bin
              logger.info "Assembler #{target.name} was not installed"
              missing = bin_paths
                          .select{ |path| path.nil? }
                          .map{ |path, i| target.binaries[i] }
              logger.info "(missing binaries: #{missing.join(', ')})"
            else
              @assemblers << target
            end
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
    def list_assemblers

      if @assemblers.empty?
        log.warn "No assemblers are installed! Please install some."
        return
      end

      str = Controller.header

      str << <<-EOS

Available assemblers are listed below.
Shortnames are shown in brackets if available.

Assemblers:
EOS
      @assemblers.each do |a|
        p = " - #{a.name}"
        p += " (#{a.shortname})" if a.respond_to? :shortname
        str << p
      end

      puts str
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
              :type => TypeMap.class_from_type(opts[:type])
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
        a.name == assembler ||
        a.shortname == assembler
      end
      raise "couldn't find assembler #{assembler}" if ret.nil?
      ret
    end

    # Run the final assembly using the specified assembler
    # and the optimal set of parameters.
    #
    # @param assembler [Biopsy::Target] the assembler
    # @param result [Hash] the optimal set of parameters
    #   as chosen by the optimisation algorithm
    def final_assembly assembler, result
      Dir.mkdir('final_assembly') unless Dir.exist? 'final_assembly'
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
      res = nil
      # load reference and create ublast DB
      @assembler_opts[:reference] =
        Transrate::Assembly.new(@assembler_opts[:reference])
      ra = Transrate::ReciprocalAnnotation.new(@assembler_opts[:reference],
                                               @assembler_opts[:reference])
      ra.make_reference_db

      # setup the assembler
      a = self.get_assembler assembler

      if @global_opts[:optimal_parameters]
        logger.info 'optimal parameters provided by user; skipping' +
                  ' optimisation to perform final assembly'
        File.open(@global_opts[:optimal_parameters], 'r') do |f|
          res_json = f.read
          res = JSON.parse(res_json, symbolize_names: true)
        end
      else
        # subsampling
        if @global_opts[:skip_subsample]
          @assembler_opts[:left_subset] = assembler_opts[:left]
          @assembler_opts[:right_subset] = assembler_opts[:right]
        else
          subsample_input
        end

        # run the optimisation
        a.setup_optim(@global_opts, @assembler_opts)
        e = Biopsy::Experiment.new(a,
                                   options: @assembler_opts,
                                   threads: @global_opts[:threads],
                                   verbosity: :loud)
        res = e.run

        # write out the result
        File.open(@global_opts[:output_parameters], 'wb') do |f|
          f.write(JSON.pretty_generate(res))
        end
      end

      # run the final assembly
      a.setup_full(@global_opts, @assembler_opts)
      unless @global_opts[:skip_final]
        res.merge! @assembler_opts
        final_assembly a, res
      end
    end # run

  end

end
