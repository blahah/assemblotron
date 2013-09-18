class CollapseFactor < BiOpSy::ObjectiveFunction
	def run (raw_output, output_files, threads)
		return raw_output.comparative_metrics.collapse_factor
	end
end