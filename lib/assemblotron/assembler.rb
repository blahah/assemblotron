module Assemblotron

  class Assembler < Biopsy::Target

    attr_accessor :bindeps

    # store the values in +:config+, checking they are valid
    def store_config config
      logger.error("Definition for #{config[:name]} must specify required binary dependencies") unless config.key?(:bindeps)
      @bindeps = config[:bindeps]
      super config
    end

  end

end
