# coding: utf-8
require 'biopsy'
require 'logger'
require 'transrate'
require 'assemblotron/version'
require 'assemblotron/sample'
require 'assemblotron/controller'
require 'pp'
require 'json'

# An automated transcriptome assembly optimiser.
#
# Assemblotron takes a random subset of your input
# reads and uses the subset to optimise the settings
# of *any* assembler, then runs the assembler with
# the full set of reads and the optimal settings.
module Assemblotron

  include Transrate

end # Assemblotron
