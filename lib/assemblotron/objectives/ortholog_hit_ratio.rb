class OrthologHitRatio < Biopsy::ObjectiveFunction
	def run (raw_output, output_files, threads)
		return raw_output.comparative_metrics.ortholog_hit_ratio
	end
end