# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require File.expand_path('../lib/assemblotron/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = 'assemblotron'
  gem.authors       = [ "Richard Smith" ]
  gem.email         = "rds45@cam.ac.uk"
  gem.homepage      = 'https://github.com/blahah/assemblotron'
  gem.summary       = %q{ automatically produce *optimal* assemblies from DNA/RNA sequencing reads }
  gem.version       = Assemblotron::VERSION::STRING.dup

  gem.files = Dir['Rakefile', '{lib,test}/**/*', 'README*', 'LICENSE*']
  gem.require_paths = %w[ lib ]

  gem.add_dependency 'rake', '~> 10.1.0'
  gem.add_dependency 'biopsy', '0.1.6.alpha'
  gem.add_dependency 'trollop', '~> 2.0'
  gem.add_dependency 'transrate', '0.0.12'
  gem.add_dependency 'inline'

  gem.add_development_dependency 'minitest'
  gem.add_development_dependency 'turn'
  gem.add_development_dependency 'simplecov'
  gem.add_development_dependency 'shoulda-context'
  gem.add_development_dependency 'coveralls', '~> 0.6.7'
end
