# The objective function for the simulation procedure.
#
# This class conforms to the API for a Biopsy::ObjectiveFunction.
class SimulatorObjective < Biopsy::ObjectiveFunction

  # Lookup the assembly score
  #
  # @param raw_output [Hash] hash containing simmulator data and current params
  # @param output_files [Array<String>] ignore (required by the API)
  # @param threads [Integer] ignored (required by the API)
  #
  # @return [Float] Assembly score,
  def run(raw_output, output_files, threads)
    raw_output[:simdata][raw_output[:params]].to_f
  end

end
