# The objective function for the optimisation procedure.
#
# This class conforms to the API for a Biopsy::ObjectiveFunction.
class AssemblyScore < Biopsy::ObjectiveFunction

  # Score the assembly.
  #
  # @param raw_output [Transrate::Transrater]
  # @param output_files [Array<String>] ignore (required by the API)
  # @param threads [Integer] ignored (required by the API)
  #
  # @return [Float] Assembly score,
  def run(raw_output, output_files, threads)
    return 0 if raw_output.nil?
    raw_output.assembly_optimal_score.first
  end

end
