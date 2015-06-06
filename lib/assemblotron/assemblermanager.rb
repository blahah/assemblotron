module Assemblotron

  class AssemblerManager

    attr_accessor :assemblers, :assemblers_uninst

    def initialize options
      @assemblers = []
      @assemblers_uninst = []
      @options = options
      load_assemblers
    end

    # Discover and load available assemblers.
    def load_assemblers
      Biopsy::Settings.instance.target_dir.each do |dir|
        Dir.chdir dir do
          Dir['*.yml'].each do |file|
            name = File.basename(file, '.yml')
            target = Assembler.new
            target.load_by_name name
            unless System.match? target.bindeps[:url]
              logger.info "Assembler #{target.name} is not available" +
                          " for this operating system"
              next
            end
            bin_paths = target.bindeps[:binaries].map do |bin|
              Which.which bin
            end
            missing_bin = bin_paths.any? { |path| path.empty? }
            if missing_bin
              logger.debug "Assembler #{target.name} was not installed"
              missing = bin_paths
                .select{ |path| path.empty? }
                .map.with_index{ |path, i| target.bindeps[:binaries][i] }
              logger.debug "(missing binaries: #{missing.join(', ')})"
              @assemblers_uninst << target
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
    def assembler_names
      a = []
      @assemblers.each do |t|
        a << t.name
        a << t.shortname if t.shortname
      end
      a
    end # assemblers

    # Return a help message listing installed assemblers.
    def list_assemblers

      str = ""

      if @assemblers.empty?
        str << "\nNo assemblers are currently installed! Please install some.\n"
      else
        str << <<-EOS

Installed assemblers are listed below.
Shortnames are shown in brackets if available.

Assemblers installed:
  EOS
        @assemblers.each do |a|
          p = "  - #{a.name}"
          p += " (#{a.shortname})" if a.respond_to? :shortname
          str << p + "\n"
        end

      end

      if @assemblers_uninst.empty?
        str << "\nAll available assemblers are already installed!\n"
      else
        str << <<-EOS

Assemblers that are available to be installed are listed below.
To install one, use:

atron --install-assemblers <name OR shortname>

Assemblers installable:
EOS

        @assemblers_uninst.each do |a|
          p = "  - #{a.name}"
          p += " (#{a.shortname})" if a.respond_to? :shortname
          str << p + "\n"
        end
      end

      str + "\n"
    end # list_assemblers

    def install_assemblers(which='all', dir='~/.local')

      dir = File.expand_path dir
      unless File.exist? dir
        FileUtils.mkdir_p dir
      end

      assembler_deps = {}
      Biopsy::Settings.instance.target_dir.each do |dir|
        Dir.chdir dir do
          Dir['*.yml'].each do |file|
            dephash = YAML.load_file file
            assembler_deps[dephash['name']] = dephash['bindeps']
            assembler_deps[dephash['shortname']] = dephash['bindeps']
          end
        end
      end

      assemblers = [which]
      if which == 'all'
        assemblers = assembler_deps.keys
      end

      to_install = assembler_deps.keys.select do |a|
        assemblers.include?(a)
      end

      if to_install.empty?
        logger.error "Tried to install #{which}, but it wasn't available"
        exit(1)
      end

      to_install.each do |assembler|
        bindeps = assembler_deps[assembler]
        unpack = bindeps.key?('unpack') ? bindeps['unpack'] : true;
        libraries = bindeps.key?('libraries') ? bindeps['libraries'] : []
        dep = Bindeps::Dependency.new(assembler,
          bindeps['binaries'],
          bindeps['version'],
          bindeps['url'],
          unpack,
          libraries)
        dep.install_missing dir
      end

    end

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

    # Run optimisation and final assembly for each assembler
    def run_all_assemblers options
      res = {}

      unless options[:skip_final]
        if (File.exist? 'final_assemblies')
          log.warn("Directory final_assemblies already exists. Some results may be overwritten.")
        end
        FileUtils.mkdir_p('final_assemblies')
        final_dir = File.expand_path 'final_assemblies'
      end

      @assemblers.each do |assembler|
        logger.info "Starting optimisation for #{assembler.name}"

        res[assembler.name] = run_assembler assembler
        logger.info "Optimisation of #{assembler.name} finished"

        # run the final assembly
        unless options[:skip_final]

          this_final_dir = File.join(final_dir, assembler.name.downcase)
          Dir.chdir this_final_dir do
            logger.info "Running full assembly for #{assembler.name}" +
                        " with optimal parameters"
            # use the full read set
            res[:left] = options[:left]
            res[:right] = options[:right]
            final = final_assembly assembler, res
            res[assembler.name][:final] = final
          end

        end
      end
      logger.info "All assemblers optimised"
      res
    end

    # Run optimisation for the named assembler
    #
    # @param [String] assembler name or shortname
    def run_assembler assembler
      # run the optimisation
      opts = @options.clone
      opts[:left] = opts[:left_subset]
      opts[:right] = opts[:right_subset]
      exp = Biopsy::Experiment.new(assembler,
                                   options: opts,
                                   threads: @options[:threads],
                                   timelimit: @options[:timelimit],
                                   verbosity: :loud)
      exp.run
    end

    # Run the final assembly using the specified assembler
    # and the optimal set of parameters.
    #
    # @param assembler [Biopsy::Target] the assembler
    # @param result [Hash] the optimal set of parameters
    #   as chosen by the optimisation algorithm
    def full_assembly assembler, options
      assembler.run options
    end

  end

end
