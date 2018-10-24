# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'umakadata/version'

Gem::Specification.new do |spec|
  spec.name          = 'umakadata'
  spec.version       = Umakadata::VERSION
  spec.authors       = ['Level Five Co., Ltd.']
  spec.email         = ['dev@level-five.jp']

  spec.summary       = 'Umaka Data Tools'
  spec.description   = 'Umaka Data Tools'
  spec.homepage      = 'TODO: Put your gem\'s website or public repo URL here.'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'awesome_print'
  spec.add_development_dependency 'bundler', '~> 1.10'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.4'
  spec.add_development_dependency 'yard', '~> 0.9.12'

  spec.add_dependency 'activesupport', '~> 4.2.6'
  spec.add_dependency 'json-ld', '~> 3.0'
  spec.add_dependency 'rdf', '~> 3.0'
  spec.add_dependency 'rdf-json', '< 4.0', '>= 2.2'
  spec.add_dependency 'rdf-n3', '~> 3.0'
  spec.add_dependency 'rdf-rdfa', '~> 3.0'
  spec.add_dependency 'rdf-rdfxml', '< 4.0', '>= 2.2.1'
  spec.add_dependency 'rdf-turtle', '~> 3.0'
  spec.add_dependency 'rdf-vocab', '~> 3.0'
  spec.add_dependency 'rdf-xsd', '~> 3.0'
  spec.add_dependency 'sparql', '~> 3.0'
  spec.add_dependency 'sparql-client', '~> 3.0'
end
