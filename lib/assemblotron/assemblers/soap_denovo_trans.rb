require 'transrate'

class SoapDenovoTrans

  include Which

  def initialize
    @count = 0
    @path = which('SOAPdenovo-Trans-127mer')
    raise "SOAPdenovo-Trans-127mer was not in the PATH" if @path.empty?
    @path = File.basename(@path.first)
  end

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

  def include_defaults params
    defaults = {
      :K => 23,
      :threads => 8,
      :out => 'sdt',
      :config => 'soapdt.config',
      :d => 0,
      :e => 2,
      :M => 1,
      :F => true,
      :L => 100,
      :t => 5,
      :G => 50
    }
    # params argument takes precedence over defaults in merge
    defaults.merge(params) { |key, v1, v2| v2 }
  end

  def construct_command(params)
    params = self.include_defaults params
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

  # runs SOAPdt script
  def run_soap(params)
    cmd = self.construct_command(params)
    `#{cmd} > #{@count}.log`
  end

end # SoapDenovoTrans
