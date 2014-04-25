require 'transrate'

# The SOAPdenovo-trans assembler.
class SoapDenovoTrans

  include Which

  # Create a new SoapDenovoTrans object
  #
  # @return [SoapDenovoTrans] the SoapDenovoTrans
  def initialize
    @count = 0
    @path = which('SOAPdenovo-Trans-127mer')
    raise "SOAPdenovo-Trans-127mer was not in the PATH" if @path.empty?
    @path = @path.first
  end

  # Run the assembler with the provided parameters.
  #
  # @param params [Hash] the parameters to use for
  #   running the assembler.
  #
  # @return [Transrate::ComparativeMetrics] metrics object
  #   containing the assembly and its reference.
  def run params
    # run the assembly
    self.run_soap params
    # retrieve output
    scaffolds = Dir['*.scafSeq']
    return nil if scaffolds.empty?
    scaffolds = scaffolds.first
    return nil if File.size(scaffolds) == 0
    # return a ComparativeMetrics object
    assembly = Transrate::Assembly.new(scaffolds)
    Transrate::ComparativeMetrics.new(assembly, params[:reference])
  end

  # Perform any necessary setup for the assembler
  # prior to running the parameter optimisation.
  #
  # This method is called by the Controller *after* 
  # *after* running the subsampler but *before* running
  # the optimisation.
  #
  # Sets up the SOAPdenovo-trans config file with
  # the subsampled read files and stores the config
  # file path in `assembler_opts[:config]`.
  #
  # @note this method may modify its input variables.
  #
  # @param global_opts [Hash] the Assemblotron global options
  # @param asssembler_opts [Hash] the assembler-specific options
  #
  # @return undefined
  def setup_optim(global_opts, assembler_opts)
    # setup config file for subsetted reads
    puts 'peforming setup for SoapDenovotrans optimisation'
    left = assembler_opts[:left_subset]
    right = assembler_opts[:right_subset]
    f = create_config(left, right, assembler_opts)
    assembler_opts[:config] = f
  end

  # Perform any necessary setup for the assembler
  # prior to running the full optimal assembly.
  #
  # This method is called *after* optimisation but
  # *before* running the final assembly.
  #
  # Sets up the SOAPdenovo-trans config file with
  # the full read files and stores the config
  # file path in `assembler_opts[:config]`, overwriting
  # any path already there.
  #
  # @note this method may modify its input variables.
  #
  # @param global_opts [Hash] the Assemblotron global options
  # @param asssembler_opts [Hash] the assembler-specific options
  #
  # @return undefined
  def setup_full(global_opts, assembler_opts)
    # set config file for full read set
    left = assembler_opts[:left]
    right = assembler_opts[:right]
    f = create_config(left, right, assembler_opts)
    assembler_opts[:config] = f
  end

  # Generate a SOAPdenovo-trans config file with the specified
  # reads.
  #
  # @param left [String] file path to the FASTQ file containing the
  #   left reads.
  # @param right [String] file path to the FASTQ file containing the
  #   right reads.  # read input files, returning the full path to the config file.
  # @param asssembler_opts [Hash] the assembler-specific options
  #
  # @return [String] full path to the generated config gile
  def create_config left, right, assembler_opts
  	puts 'creating a SoapDenovoTrans config file'
    filename = "#{Time.now.nsec}.config"
    File.open(filename, 'w') do |f|
      f.puts 'max_rd_len=5000'
      f.puts '[LIB]'
      f.puts "avg_ins=#{assembler_opts[:insertsize]}"
      f.puts "reverse_seq=0" # don't reverse complement the reads
      f.puts "asm_flags=3"   # use the reads for assembly and scaffolding
      f.puts "q1=#{left}"
      f.puts "q2=#{right}"
    end
    filename = File.expand_path filename
    puts "config file created: #{filename}"
    filename 
  end

  # Merge the default parameters with those provided.
  #
  # @note the default parameters are hard-coded in this method.
  #
  # @param params [Hash] parameters to merge with the defaults.
  #
  # @return [Hash] the merged parameters.
  def include_defaults params
    defaults = {
      :K => 23,
      :threads => 8,
      :out => 'sdt',
      :d => 0,
      :e => 2,
      :M => 1,
      :F => true,
      :L => 100,
      :t => 5,
      :G => 50
    }
    defaults.merge params
  end

  # Construct the command to run SOAPdenovo-trans using
  # the given parameters and filling in any unspecified
  # parameters with explicit defaults.
  #
  # @param params [Hash] assembly parameters
  #
  # @return [String] the constructed command
  def construct_command params
    params = self.include_defaults params
    # validate the input
    unless params.has_key? :config
      msg = "SoapDenovoTrans requires a config file to be passed in"
      raise ArgumentError.new msg
    end
    cmd = "#{@path} all"
    # generic
    cmd += " -s #{params[:config]}" # config file
    cmd += " -a #{params[:memory]}" if params.has_key? :memory # memory assumption
    cmd += " -o #{params[:out]}" if params.has_key? :out # output directory
    cmd += " -p #{params[:threads]}" # number of threads
    # specific
    cmd += " -K #{params[:K]}" # kmer size
    cmd += " -d #{params[:d]}" # minimum kmer frequency
    cmd += " -F" if params[:F] # fill gaps in scaffold
    cmd += " -M #{params[:M]}" # strength of contig flattening
    cmd += " -L #{params[:L]}" # minimum contig length
    cmd += " -e #{params[:e]}" # delete contigs with coverage no greater than
    cmd += " -t #{params[:t]}" # maximum number of transcripts from one locus
    cmd += " -G #{params[:G]}" # allowed length difference between estimated and filled gap
    puts cmd
    cmd
  end

  # Run the SOAPdenovo-trans assembler with the specified
  # parameters.
  #
  # @param params [Hash] assembly parameters
  #
  # @return [String] STDOUT output of the assembly run
  def run_soap(params)
    cmd = self.construct_command(params)
    `#{cmd} > #{@count}.log`
  end

end # SoapDenovoTrans
