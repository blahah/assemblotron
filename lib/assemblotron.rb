# coding: utf-8
require 'assemblotron/hash'
require 'bindeps'
require 'fixwhich'
require 'transrate'
require 'biopsy'
require 'transfuse'
require 'fileutils'
require 'assemblotron/cmd'
require 'assemblotron/version'
require 'assemblotron/sample'
require 'assemblotron/typemap'
require 'assemblotron/system'
require 'assemblotron/assembler'
require 'assemblotron/assemblermanager'
require 'assemblotron/controller'
require 'pp'
require 'json'
require 'yell'

# An automated transcriptome assembly optimiser.
#
# Assemblotron takes a random subset of your input
# reads and uses the subset to optimise the settings
# of *any* assembler, then runs the assembler with
# the full set of reads and the optimal settings.
module Assemblotron

  include Transrate

  # Create the universal logger and include it in Object
  # making the logger object available everywhere
  format = Yell::Formatter.new("[%5L] %d : %m", "%Y-%m-%d %H:%M:%S")
  # http://xkcd.com/1179/
  Yell.new(:format => format) do |l|
    l.level = :info
    l.name = Object
    l.adapter STDOUT, level: [:debug, :info, :warn]
    l.adapter STDERR, level: [:error, :fatal]
  end
  Object.send :include, Yell::Loggable

end # Assemblotron
