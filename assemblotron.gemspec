# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require File.expand_path('../lib/assemblotron/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = 'assemblotron'
  gem.authors       = [ "Richard Smith-Unna", "Parsa Akbari",
                        "Chris Boursnell" ]
  gem.email         = "rds45@cam.ac.uk"
  gem.homepage      = 'https://github.com/blahah/assemblotron'
  gem.summary       = %q{ automatically produce *optimal* assemblies from DNA/RNA sequencing reads }
  gem.version       = Assemblotron::VERSION::STRING.dup

  gem.files = Dir['Rakefile', '{lib,test}/**/*', 'README*', 'LICENSE*']
  gem.require_paths = %w[ lib ]

  gem.add_dependency 'yell', '~> 2.0', '>= 2.0.4'
  gem.add_dependency 'biopsy', '0.2.1'
  gem.add_dependency 'trollop', '~> 2.0'
  gem.add_dependency 'transrate', '1.0.0.beta4'
  gem.add_dependency 'fixwhich', '~> 1.0', '>= 1.0.2'
  gem.add_dependency 'RubyInline', '~> 3.12'
  gem.add_dependency 'transfuse', '~> 0.1.0'
  gem.add_dependency 'chronic_duration', '~> 0.10.6', '>= 0.10.6'
  gem.add_dependency 'bindeps', '~> 1.2', '1.2.0'

  gem.add_development_dependency 'rake', '~> 10.3', '>= 10.3.2'
  gem.add_development_dependency 'minitest', '~> 5.0'
  gem.add_development_dependency "minitest-reporters", "~> 1"
  gem.add_development_dependency 'simplecov', '~> 0.8', '>= 0.8.2'
  gem.add_development_dependency 'shoulda-context', '~> 1.2', '>= 1.2.1'
  gem.add_development_dependency 'coveralls', '~> 0.7', '>= 0.7.2'
end
