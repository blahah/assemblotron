class SoapDenovoTrans

  def initialize
    @count = 0
  end

  def run params
    # run the assembly
    self.setup_soap(params) if @count == 0
    self.run_soap params
    @count += 1
    # retrieve output
    scaffolds = Dir['*.scafSeq']
    return nil if scaffolds.empty?
    scaffolds = scaffolds.first
    # return a Transrater
    Transrater.new scaffolds
  end

  def include_defaults params
    defaults = {
      :K => 23,
      :p => 8,
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

  def construct_command(params)
    params = self.include_defaults params
    cmd = "#{params[:path]} all"
    # generic
    cmd += " -s soapdt.config" # config file
    cmd += " -a #{params[:memory]}" # memory assumption
    cmd += " -o #{params[:out]}" # output directory
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