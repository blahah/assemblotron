module Assemblotron

  class TypeMap

    # Given the name of a type, return its class
    #
    # @param [String] type
    # @return [Class] the class corresponding to the type
    def self.class_from_type type
      case type
      when 'str'
        String
      when 'string'
        String
      when 'int'
        Integer
      when 'integer'
        Integer
      when 'float'
        Float
      end
    end

  end

end
