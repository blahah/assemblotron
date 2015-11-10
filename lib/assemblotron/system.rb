module Assemblotron

  # A collection of methods for getting information about the
  # system on which Assemblotron is running. This information
  # is used when installing assemblers and for giving feedback
  # to the user about platform-specific limitations.
  class System

    require 'rbconfig'

    # Get the host operating system.
    #
    # @return [Symbol] the host operating name, one of
    #   `:linux`, `:unix`, `:macosx`, or `:windows`
    def self.os
      host_os = RbConfig::CONFIG['host_os']
      case host_os
      when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
        :windows
      when /darwin|mac os/
        :macosx
      when /linux/
        :linux
      when /solaris|bsd/
        :unix
      else
        raise Error::WebDriverError, "unknown os: #{host_os.inspect}"
      end
    end

    # Get the wordsize of the system processor architecture
    #
    # @return [Integer] 32 on a 32bit system, 64 on a 64bit system
    def self.wordsize
      ['a'].pack('P').length == 4 ? 32 : 64
    end

    def self.match? system
      bit = "#{System.wordsize}bit".to_sym

      if (system.key? bit)
        # correct wordsize supported
        if (system[bit].key? System.os)
          # host OS supported
          return true
        end
      end
      false
    end

  end

end
