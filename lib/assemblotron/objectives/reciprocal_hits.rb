class ReciprocalHits < Biopsy::ObjectiveFunction
	def run (raw_output, output_files, threads)
		return raw_output.comparative_metrics.reciprocal_hits
	end
end