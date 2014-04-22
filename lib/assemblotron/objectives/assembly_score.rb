class AssemblyScore < Biopsy::ObjectiveFunction
  def run (raw_output, output_files, threads)
    return 0 if raw_output.nil?
    raw_output.run
    raw_output.reference_coverage
  end
end
