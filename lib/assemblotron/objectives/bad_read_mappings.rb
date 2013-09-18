class BadReadMappings < BiOpSy::ObjectiveFunction
	def run (raw_output, output_files, threads)
		return raw_output.read_metrics.bad
	end
end