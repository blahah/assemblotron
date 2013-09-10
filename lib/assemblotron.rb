require "assemblotron/assemblers/constructors/soap_denovo_trans"
require "biopsy"

# settings
s = Biopsy::Settings.instance
s.set_defaults
s.domain = 'assemblotron'
libdir = File.dirname(__FILE__)
s.domain_dir = [File.join(libdir, 'assemblotron')]
s.target_dir = [File.join(libdir, 'assemblotron/assemblers/definitions')]