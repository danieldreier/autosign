# Ensure we require the local version and not one we might have installed already
require File.join([File.dirname(__FILE__),'lib','autosign','version.rb'])
spec = Gem::Specification.new do |s| 
  s.name = 'autosign'
  s.version = Autosign::VERSION
  s.author = 'Your Name Here'
  s.email = 'your@email.address.com'
  s.homepage = 'http://your.website.com'
  s.platform = Gem::Platform::RUBY
  s.summary = 'A description of your project'
  s.files = `git ls-files`.split("
")
  s.require_paths << 'lib'
  s.has_rdoc = true
  s.extra_rdoc_files = ['README.rdoc','autosign.rdoc']
  s.rdoc_options << '--title' << 'autosign' << '--main' << 'README.rdoc' << '-ri'
  s.bindir = 'bin'
  s.executables << 'autosign'
  s.add_development_dependency('rake')
  s.add_development_dependency('rdoc')
  s.add_development_dependency('aruba')
  s.add_development_dependency('cucumber')
  s.add_development_dependency('puppet')
  s.add_runtime_dependency('gli','~> 2')
  s.add_runtime_dependency('jwt','~> 1')
  s.add_runtime_dependency('iniparse','~> 1')
  s.add_runtime_dependency('logging')
  s.add_runtime_dependency('json')
  s.add_runtime_dependency('deep_merge')
  s.add_runtime_dependency('require_all')
  s.add_runtime_dependency('yard')
end
