require 'fixwhich'
require 'transrate'

class IdbaTran

  def initialize
    @idba = Which::which('idba_tran').first
    @fq2fa = Which::which('fq2fa').first
  end

  # Run the assembler with the provided parameters.
  #
  # @param params [Hash] the parameters to use for
  #   running the assembler.
  #
  # @return [Transrate::Transrater] transrater object
  #   containing the assembly and its reference.
  def run params
    contigs = run_idba params

    return nil if File.size(contigs) == 0

    assembly = Transrate::Assembly.new(contigs)
    transrater = Transrate::Transrater.new(assembly, nil,
                                           threads:params[:threads])
    transrater.read_metrics(params[:left], params[:right])
    transrater
  end

  def run_idba options
    idba = Assemblotron::Cmd.new build_cmd(options)
    output = File.expand_path("contig.fa")
    idba.run
    unless idba.status.success?
      puts "Something went wrong with idba"
      puts idba.stderr
      puts idba.stdout
    end
    return output
  end

  def build_cmd params
    puts params
    reads = prepare_reads(params[:left], params[:right])
    idba_cmd = "#{@idba} "
    idba_cmd << "-o . "            # output
    idba_cmd << "-r #{reads} "              # input
    idba_cmd << "--num_threads #{params[:threads]} " # number of threads
    idba_cmd << "--mink 21 "                # minimum k value (<=124)
    idba_cmd << "--maxk 77 "                # maximum k value (<=124)
    idba_cmd << "--step 4 "                 # increment k
    idba_cmd << "--min_count 1 "            # minimum multiplicity for filter
    idba_cmd << "--no_correct "             # do not do correction
    idba_cmd << "--max_isoforms 6 "         # maximum number of isoforms
    idba_cmd << "--similar 0.98"            # similarity for alignment
    return idba_cmd
  end

  def prepare_reads left, right
    output = File.basename("idba_merged_reads.fa")
    unless File.exist?(output)
      cmd = "#{@fq2fa} --merge #{left} #{right} #{output}"
      merge = Assemblotron::Cmd.new cmd
      merge.run
    end
    return output
  end

end
