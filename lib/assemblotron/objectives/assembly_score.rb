# The objective function for the optimisation procedure.
#
# The AssemblyScore is the proportion of the reference
# (with amino-acid resolution) that is reconstructed in
# assembly, as measured by Transrate.
#
# This class conforms to the API for a Biopsy::ObjectiveFunction.
class AssemblyScore < Biopsy::ObjectiveFunction

  # Score the assembly.
  #
  # @param raw_output [Transrate::ComparativeMetrics]
  # @param output_files [Array<String>] ignore (required by the API)
  # @param threads [Integer] ignored (required by the API)
  #
  # @return [Float] Assembly score,
  def run (raw_output, output_files, threads)
    return 0 if raw_output.nil?
    raw_output.run
    raw_output.reference_coverage
  end
end
