require 'transrate'
require 'fixwhich'

# The SOAPdenovo-trans assembler.
class SoapDenovoTrans

  include Which

  # Create a new SoapDenovoTrans object
  #
  # @return [SoapDenovoTrans] the SoapDenovoTrans
  def initialize
    @count = 0
    @path = which 'SOAPdenovo-Trans-127mer'
    @path = @path.first if !(@path.nil?)
  end

  # Run the assembler with the provided parameters.
  #
  # @param params [Hash] the parameters to use for
  #   running the assembler.
  #
  # @return [Transrate::Transrater] transrater object
  #   containing the assembly and its reference.
  def run params

    run_soap params

    # retrieve output
    scaffolds = Dir['*.scafSeq']
    return nil if scaffolds.empty?
    scaffolds = scaffolds.first
    return nil if File.size(scaffolds) == 0

    assembly = Transrate::Assembly.new(scaffolds)
    transrater = Transrate::Transrater.new(assembly, nil,
                                           threads:params[:threads])
    transrater.read_metrics(params[:left], params[:right])
    transrater
  end

  # Generate a SOAPdenovo-trans config file with the specified
  # reads.
  #
  # @param options [Hash] assembly options
  #
  # @return [String] full path to the generated config gile
  def create_config options
    filename = "#{Time.now}.full.config".tr(" ","_").tr(":",".")
    File.open(filename, 'w') do |f|
      f.puts 'max_rd_len=200'
      f.puts '[LIB]'
      f.puts "avg_ins=#{options[:insert_size]}"
      f.puts "reverse_seq=0" # don't reverse complement the reads
      f.puts "asm_flags=3"   # use the reads for assembly and scaffolding
      f.puts "rd_len_cutoff=150"
      f.puts "map_len=50"
      f.puts "q1=#{options[:left]}"
      f.puts "q2=#{options[:right]}"
    end
    filename = File.expand_path filename
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
  def construct_command params, config_path
    params = self.include_defaults params

    cmd = "#{@path} all"
    # generic
    cmd += " -s #{config_path}" # config file
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
    cmd
  end

  # Run the SOAPdenovo-trans assembler with the specified
  # parameters.
  #
  # @param params [Hash] assembly parameters
  #
  # @return [String] STDOUT output of the assembly run
  def run_soap params
    config_path = create_config params
    cmd_string = self.construct_command(params, config_path)
    cmd = Assemblotron::Cmd.new cmd_string
    cmd.run
    if (!cmd.status.success?)
      raise "cmd failed:\n#{cmd_string}\nstderr:\t#{cmd.stderr}\nstdout:\t#{cmd.stdout}"
    end
  end

end # SoapDenovoTrans