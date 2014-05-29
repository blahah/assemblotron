# An objective function that returns 0
#
# This class conforms to the API for a Biopsy::ObjectiveFunction.
class NoScore < Biopsy::ObjectiveFunction

  # Don't do anything just return 0.
  #
  # @return [Integer] 0,
  def run (raw_output, output_files, threads)
    return 0
  end
end
