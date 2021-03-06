# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'reasonable/value/version'

Gem::Specification.new do |spec|
  spec.name = 'reasonable-value'
  spec.version = Reasonable::Value::VERSION
  spec.authors = ['Thomas Larrieu']
  spec.email = ['thomas.larrieu@gmail.com']

  spec.summary = 'Simple value object gem with straighforward type validation'
  spec.homepage = 'https://www.github.com/jobteaser/reasonable'
  spec.license = 'MIT'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = %w(lib)

  spec.add_dependency 'activesupport'

  spec.add_development_dependency 'bundler', '~> 1.14'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.59.2'
end
