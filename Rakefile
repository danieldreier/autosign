require 'rubygems'
begin
  require 'rspec/core/rake_task'
  require 'cucumber'
  require 'cucumber/rake/task'
  require 'rdoc/task'
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.rspec_opts = '--format documentation'
  end
rescue LoadError
end
require 'rake/clean'
require 'rubygems/package_task'
Rake::RDocTask.new do |rd|
  rd.main = "README.rdoc"
  rd.rdoc_files.include("README.rdoc","lib/**/*.rb","bin/**/*")
  rd.title = 'Your application title'
end

spec = eval(File.read('autosign.gemspec'))

Gem::PackageTask.new(spec) do |pkg|
end
CUKE_RESULTS = 'results.html'
CLEAN << CUKE_RESULTS
desc 'Run features'

Cucumber::Rake::Task.new(:features) do |t|
  t.cucumber_opts = "features --format pretty"
end

desc 'Run features tagged as work-in-progress (@wip)'
Cucumber::Rake::Task.new('features:wip') do |t|
  tag_opts = ' --tags ~@pending'
  tag_opts = ' --tags @wip'
  t.cucumber_opts = "features --format html -o #{CUKE_RESULTS} --format pretty -x -s#{tag_opts}"
  t.fork = false
end

task 'cucumber:wip' => 'features:wip'
task :wip => 'features:wip'
require 'rake/testtask'
Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/*_test.rb']
end

task :ci => [:spec, :features]

task :default => [:test,:features]
