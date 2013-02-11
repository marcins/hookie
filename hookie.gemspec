# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'hookie'

Gem::Specification.new do |gem|
  gem.name          = "hookie"
  gem.version       = Hookie::VERSION
  gem.authors       = ["Marcin Szczepanski"]
  gem.email         = ["marcins@webqem.com"]
  gem.description   = %q{Framework for writing gitolite hooks with Ruby}
  gem.summary       = %q{Framework for writing gitolite hooks with Ruby}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'grit', '~> 2.5.0'
end
