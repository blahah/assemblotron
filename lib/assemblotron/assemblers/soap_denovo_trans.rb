require 'transrate'

class SoapDenovoTrans

  include Which

  # Return a new SoapDenovoTrans object
  def initialize
    @count = 0
    @path = which('SOAPdenovo-Trans-127mer')
    raise "SOAPdenovo-Trans-127mer was not in the PATH" if @path.empty?
    @path = @path.first
  end

  # Run the assembler with the provided parameters,
  # returning a Transrate::ComparativeMetrics object
  # containing a score for the generated assembly
  # compared to the reference.
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
  # This includes modifying the config file to point
  # to the subsetted reads rather than the full set.
  def setup_optim(global_opts, assembler_opts)
    # setup config file for subsetted reads
    left = assembler_opts[:left_subset]
    right = assembler_opts[:right_subset]
    f = create_config(left, right, assembler_opts)
    assembler_opts[:config] = f
  end

  # Perform any necessary setup for the assembler
  # prior to running the full optimal assembly.
  # This includes resetting the config to refer
  # to the full set of reads.
  def setup_full(global_opts, assembler_opts)
    # set config file for full read set
    left = assembler_opts[:left]
    right = assembler_opts[:right]
    f = create_config(left, right, assembler_opts)
    assembler_opts[:config] = f
  end

  # Generate a config file with the specified left and right
  # read input files, returning the full path to the config file.
  def create_config left, right, assembler_opts
    # create the config file
    filename = "#{Time.now}.full.config"
    File.open(filename) do |f|
      f << 'max_rd_len=5000'
      f << '[LIB]'
      f << "avg_ins=#{assembler_opts[:insertsize]}"
      f << "reverse_seq=0" # don't reverse complement the reads
      f << "asm_flags=3"   # use the reads for assembly and scaffolding
      f << "q1=#{left}"
      f << "q2=#{right}"
    end
    File.expand_path filename
  end

  # Merge the default parameters with the hash provided
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

  # Given a set of parameters, fill in any missing
  # parameters with defaults and construct a command
  # to run the target assembler. Return the command
  # as a string.
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
  end

  # Run the SOAPdenovo-trans assembler with the provided
  # parameters. Return the output generated.
  def run_soap(params)
    cmd = self.construct_command(params)
    `#{cmd} > #{@count}.log`
  end

end # SoapDenovoTrans
