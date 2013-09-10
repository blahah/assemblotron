# objective function to count number of 'bad' read
# pair mappings. parses sam file using flags to
# count read pairs in various categories

require 'objectivefunction.rb'
require 'pp'
require 'rubygems'
require 'better_sam'

if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby'
  # we want real posix threads if possible
  require 'jruby_threach'
else
  require 'threach'
end

class BadReadMappings < BiOpSy::ObjectiveFunction

  def run(assemblydata, threads=6)
    info "running objective: BadReadMappings"
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
    # run analysis
    self.map_reads
    # results
    return { :weighting => 1.0,
             :optimum => 0.0,
             :max => 1.0,
             :time => Time.now - t0}.merge self.parse_sam
  end

  def map_reads
    self.build_index
    unless File.exists? 'mappedreads.sam'
      # construct bowtie command
      bowtiecmd = "bowtie2 -k 3 -p #{@threads} -X #{@realistic_dist} --no-unal --local --quiet #{@assembly_name} -1 #{@left_reads}"
      # paired end?
      bowtiecmd += " -2 #{@right_reads}" if @right_reads.length > 0
      # other functions may want the output, so we save it to file
      bowtiecmd += " > mappedreads.sam"
      # run bowtie
      debug(`#{bowtiecmd}`)
    end
  end

  def build_index
    unless File.exists?(@assembly + '.1.bt2')
      `bowtie2-build --offrate 1 #{@assembly} #{@assembly_name}`
    end
  end

  def parse_sam
    diagnostics = {
      :total => 0,
      :good => 0,
      :bad => 0,
      :paired => 0,
      :unpaired => 0,
      :proper_pair => 0,
      :improper_pair => 0,
      :proper_orientation => 0,
      :improper_orientation => 0,
      :both_mapped => 0,
      :same_contig => 0,
      :realistic => 0,
      :unrealistic => 0
    }
    if File.exists?('mappedreads.sam') && `wc -l mappedreads.sam`.to_i > 0
      ls = BetterSam.new
      rs = BetterSam.new
      flags = {}
      sam = File.open('mappedreads.sam').readlines
      sam.delete_if{ |line| line[0] == "@" }.each_slice(2) do |l, r|
        if l && ls.parse_line(l) # Returns false if line starts with @ (a header line)
          diagnostics[:total] += 1
          if r && rs.parse_line(r)
            # ignore unmapped reads
            flagpair = "#{ls.flag}:#{rs.flag}"
            if flags.has_key? flagpair
              flags[flagpair] += 1
            else
              flags[flagpair] = 1
            end
            if ls.read_paired?
              # reads are paired
              diagnostics[:paired] += 1
              if ls.read_properly_paired?
                # mapped in proper pair
                diagnostics[:proper_pair] += 1
                if (ls.first_in_pair? && ls.mate_reverse_strand?) || 
                   (ls.second_in_pair? && ls.read_reverse_strand?)
                  # mates in proper orientation
                  diagnostics[:proper_orientation] += 1
                  diagnostics[:good] += 1
                else
                  # mates in wrong orientation
                  diagnostics[:improper_orientation] += 1
                  diagnostics[:bad] += 1
                end
              else
                # not mapped in proper pair
                diagnostics[:improper_pair] += 1
                unless (ls.read_unmapped?) || (ls.mate_unmapped?)
                  # both read and mate are mapped
                  diagnostics[:both_mapped] += 1
                  if ls.chrom == rs.chrom
                    # both on same contig
                    diagnostics[:same_contig] += 1
                    begin
                      if Math.sqrt((ls.pos - rs.pos) ** 2) < ls.seq.length
                        # overlap is realistic
                        diagnostics[:realistic] += 1
                        if (ls.flag & $flags[6] && ls.flag & $flags[7]) || 
                         (ls.flag & $flags[5] && ls.flag & $flags[8])
                          # mates in proper orientation
                          diagnostics[:proper_orientation]
                          diagnostics[:good] += 1
                        else
                          # mates in wrong orientation
                          diagnostics[:improper_orientation]
                          diagnostics[:bad] += 1
                        end
                      else
                        # overlap not realistic
                        diagnostics[:unrealistic] += 1
                        diagnostics[:bad] += 1
                      end
                    rescue
                      puts ls.pos
                      puts rs.pos
                    end
                  else
                    # mates on different contigs
                    # are the mapping positions within a realistic distance of
                    # the ends of contigs?
                    lcouldpair = (ls.seq.length - ls.pos) < @realistic_dist
                    lcouldpair = lcouldpair || ls.pos < @realistic_dist
                    rcouldpair = (rs.seq.length - rs.pos) < @realistic_dist
                    rcouldpair = rcouldpair || rs.pos < @realistic_dist
                    if lcouldpair && rcouldpair
                      diagnostics[:realistic] += 1
                      diagnostics[:good] += 1
                    else
                      diagnostics[:unrealistic] += 1
                      diagnostics[:bad] += 1
                    end
                  end
                end
              end
            end
          end
        end
      end
      diagnostics[:result] = diagnostics[:bad]
    end
    return diagnostics
  end

  def essential_files
    return ['mappedreads.sam']
  end

end
