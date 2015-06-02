module Assemblotron

  class AssemblerManager

    def initialize options
      @assemblers = []
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
            missing_bin = bin_paths.any? { |path| path.nil? }
            if missing_bin
              logger.info "Assembler #{target.name} was not installed"
              missing = bin_paths
                          .select{ |path| path.nil? }
                          .map{ |path, i| target.bindeps[:binaries][i] }
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

    # Return a help message listing installed assemblers.
    def list_assemblers

      if @assemblers.empty?
        logger.warn "No assemblers are installed! Please install some."
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
        str << p + "\n"
      end

      str
    end # list_assemblers

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

      Dir.mkdir('final_assemblies') unless options[:skip_final]
      final_dir = File.expand_path 'final_assemblies'

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
