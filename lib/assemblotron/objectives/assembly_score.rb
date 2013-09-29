class AssemblyScore < Biopsy::ObjectiveFunction
  def run (raw_output, output_files, threads)
    raw_output.assembly_score
  end
end
