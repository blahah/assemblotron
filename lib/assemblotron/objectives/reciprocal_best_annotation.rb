# objective function to count number of conditioned
# reciprocal best usearch annotations

require 'objectivefunction.rb'

class ReciprocalBestAnnotation < BiOpSy::ObjectiveFunction

  def run(assemblydata, threads=6)
    info "running objective: ReciprocalBestAnnotation"
    t0 = Time.now
    @threads = threads
    # extract assembly data
    @assembly = assemblydata[:assembly]
    @assembly_name = assemblydata[:assemblyname]
    @reference = assemblydata[:reference]
    # results
    res = self.rbusearch
    return { :weighting => 1.0,
             :optimum => 26000,
             :max => 26000.0,
             :time => Time.now - t0}.merge res
  end

  def rbusearch
    Dir.mkdir 'output'
    `rbusearch --query #{@assembly} --target #{@reference} --output . --cores #{@threads}`
    return {
      :result => `wc -l bestmatches.rbu`.to_i,
      :query_hits => `cut -f1 query_result.txt | sort | uniq | wc -l`.strip,
      :target_hits => `cut -f1 target_result.txt | sort | uniq | wc -l`.strip,
      :mean_q_bitscore => `awk '{sum+=$8} END { print sum/NR}' bestmatches.rbu`.strip,
      :mean_t_bitscore => `awk '{sum+=$9} END { print sum/NR}' bestmatches.rbu`.strip
    }
  end

  def essential_files
    return ['bestmatches.rbu']
  end

end