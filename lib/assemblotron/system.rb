module Assemblotron

  class System

    require 'rbconfig'

    # Returns a symbol representing the host operating
    # system: one of [:windows, :macosx, :linux, :unix]
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

    # Returns the wordsize of the processor architecture:
    # 32 on a 32bit system, 64 on a 64bit system
    def self.wordsize
      ['a'].pack('P').length == 4 ? 32 : 64
    end

    # Check if software run by #cmd is installed
    def initialize(left, right)
      @left = left
      @right = right
    end

  end

end
