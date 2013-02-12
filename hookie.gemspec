# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'hookie'

Gem::Specification.new do |gem|
  gem.name          = "hookie"
  gem.version       = Hookie::VERSION
  gem.authors       = ["Marcin Szczepanski"]
  gem.email         = ["marcins@webqem.com"]
  gem.description   = %q{Hookie provides a way to write git hooks with ruby without too much worrying about any of the plumbing required, you can easily write your own plugins and focus on the core of your functionality. 

    Hookie includes plugins for Jenkins and HipChat.}
  gem.summary       = %q{Framework for writing gitolite/git hooks with Ruby}
  gem.homepage      = "https://github.com/marcins/hookie"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'grit', '~> 2.5.0'
  gem.add_dependency 'diff-lcs', '~> 1.1.3'

  gem.add_development_dependency 'rspec', '~> 2.12.0'
  gem.add_development_dependency 'simplecov', '>= 0.4.0'
end
