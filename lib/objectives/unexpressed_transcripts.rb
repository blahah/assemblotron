# objective function to count number of unexpressed transcripts
# maps reads back to assembly and quantifies expression with eXpress
# then counts number of transcripts with 0 expression

require 'objectivefunction.rb'

class UnexpressedTranscripts < BiOpSy::ObjectiveFunction

  def run(assemblydata, threads=6)
    info "running objective: UnexpressedTranscripts"
    t0 = Time.now
    @threads = threads
    # extract assembly data
    @assembly = assemblydata[:assembly]
    @assembly_name = assemblydata[:assemblyname]
    @left_reads = assemblydata[:leftreads]
    @right_reads = assemblydata[:rightreads]
    @insertsize = assemblydata[:insertsize]
    @insertsd = assemblydata[:insertsd]
    # realistic maximum insert size is three standard deviations from the insert size
    @realistic_dist = @insertsize + (3 * @insertsd)
    # run function
    results_path = self.map_reads()
    @last_path = results_path
    # results
    result = self.count_unexpressed(results_path)
    max = `grep "^>" #{@assembly} | wc -l`.to_i
    max = max > 0 ? max : 1
    return { 
      :weighting => 1.0,
      :optimum => 0,
      :max => max.to_f,
      :result => result,
      :time => Time.now - t0 
    }
  end

  def map_reads
    self.build_index()
    unless File.exists? 'mappedreads.sam'
      # construct bowtie command
      bowtiecmd = "bowtie2 -k 3 -p #{@threads} -X #{@realistic_dist} --no-unal --local --quiet #{@assembly_name} -1 #{@left_reads}"
      # paired end?
      bowtiecmd += " -2 #{@right_reads}" if @right_reads.length > 0
      # other functions may want the output, so we save it to file
      bowtiecmd += " > mappedreads.sam"
      # run bowtie
      `#{bowtiecmd}`
    end
    unless File.exists? 'results.xprs'
      # run eXpress
      #info(`express --no-bias-correct #{@assembly} mappedreads.sam 2>1&`)
      `express --no-bias-correct #{@assembly} mappedreads.sam 2>1&`
      raise 'eXpress failed' unless $?.success?
    end
    return 'results.xprs'
  end

  def build_index
    unless File.exists?(@assembly + '.1.bt2')
      `bowtie2-build --offrate 1 #{@assembly} #{@assembly_name}`
    end
  end

  def count_unexpressed(results_path)
    return `cut -f7 #{results_path} | grep "^0" | wc -l`.to_i
  end

  def essential_files
    return ['mappedreads.sam', 'results.xprs']
  end

end
