# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'umakadata/version'

Gem::Specification.new do |spec|
  spec.name          = "umakadata"
  spec.version       = Umakadata::VERSION
  spec.authors       = ["Level Five Co., Ltd."]
  spec.email         = ["dev@level-five.jp"]

  spec.summary       = "Umaka Data Tools"
  spec.description   = "Umaka Data Tools"
  spec.homepage      = "TODO: Put your gem's website or public repo URL here."
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.4"
  spec.add_development_dependency "yard", "~> 0.9.12"

  spec.add_dependency "sparql", "~> 2.0"
  spec.add_dependency "sparql-client", "~> 2.0"
  
  spec.add_dependency "rdf-turtle", "~> 2.0"
  spec.add_dependency "rdf-rdfxml", "~> 2.0"
  spec.add_dependency "rdf-vocab", "~> 2.0"
  spec.add_dependency "rdf-n3", "~> 2.0"
  spec.add_dependency "rdf-rdfa", "~> 2.0"
  spec.add_dependency "json-ld", "~> 2.0"
  spec.add_dependency "activesupport", "~> 4.2.6"
end
