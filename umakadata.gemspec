lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'umakadata/version'

Gem::Specification.new do |spec|
  spec.name = 'umakadata'
  spec.version = Umakadata::VERSION
  spec.authors = ['Daisuke Satoh']
  spec.email = ['daisuke.satoh@lifematics.co.jp']

  spec.summary = 'Core library for Umaka Data'
  spec.description = spec.summary
  spec.homepage = 'http://yummydata.org'
  spec.license = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.3'.freeze)

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{^(test|spec|features)/})
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'awesome_print', '~> 1.8'
  spec.add_development_dependency 'bundler', '~> 1.17'
  spec.add_development_dependency 'pry-byebug', '~> 3.7'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.8'
  spec.add_development_dependency 'webmock', '~> 3.6'
  spec.add_development_dependency 'yard', '~> 0.9.12'

  spec.add_dependency 'activesupport', '>= 5.2', '< 7.0'
  spec.add_dependency 'faraday', '~> 0.15.4'
  spec.add_dependency 'faraday_middleware', '~> 0.13.1'
  spec.add_dependency 'linkeddata', '~> 3.0'
end
