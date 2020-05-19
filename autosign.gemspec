# frozen_string_literal: true

# Ensure we require the local version and not one we might have installed already
require File.join([File.dirname(__FILE__), 'lib', 'autosign', 'version.rb'])
spec = Gem::Specification.new do |s|
  s.name = 'autosign'
  s.version = Autosign::VERSION
  s.author = 'Daniel Dreier'
  s.email = 'ddreier@thinkplango.com'
  s.homepage = 'https://github.com/danieldreier/autosign'
  s.platform = Gem::Platform::RUBY
  s.summary = 'Tooling to make puppet autosigning easy, secure, and extensible'
  s.files   = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(spec|features|fixtures)/}) }
  s.require_paths << 'lib'
  s.extra_rdoc_files = [
    'CHANGELOG.md',
    'LICENSE',
    'README.md'
  ]
  s.bindir = 'bin'
  s.executables = ['autosign', 'autosign-validator']
  s.add_development_dependency('aruba', '~> 0.6')
  s.add_development_dependency('coveralls')
  s.add_development_dependency('cucumber', '~> 2')
  s.add_development_dependency('pry', '~> 0.10')
  s.add_development_dependency('puppet', '~> 3')
  s.add_development_dependency('rake', '~> 13')
  s.add_development_dependency('rdoc', '~> 4')
  s.add_development_dependency('rspec', '~> 3')
  s.add_development_dependency('rubocop', '~> 0.83.0')
  s.add_development_dependency('yard', '~> 0.9.11')
  s.add_runtime_dependency('deep_merge', '~> 1.2')
  s.add_runtime_dependency('gli', '~> 2')
  s.add_runtime_dependency('iniparse', '~> 1')
  s.add_runtime_dependency('jwt', '~> 1')
  s.add_runtime_dependency('logging', '~> 2')
  s.add_runtime_dependency('multi_json', '>=1')
end
