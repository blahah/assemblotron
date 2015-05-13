require 'open3'

module Transrate

  class Cmd

    attr_accessor :cmd, :stdout, :stderr, :status

    def initialize cmd
      @cmd = cmd
    end

    def run
      @stdout, @stderr, @status = Open3.capture3 @cmd
    end

    def to_s
      @cmd
    end

  end # Cmd

  class Which

    def self.which cmd
      which = Cmd.new("which #{cmd}")
  	  which.run
  	  if !which.status.success?
        return nil
      end
  	  which.stdout.split("\n").first
    end

  end # Which

end
