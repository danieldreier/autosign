# encoding: utf-8
# frozen_string_literal: true

require 'rubygems'
require 'bundler'
require 'bundler/gem_tasks'
require 'rake/testtask'
require 'rspec/core/rake_task'
require 'cucumber'
require 'cucumber/rake/task'
require 'rdoc/task'
require 'rake/clean'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = '--format documentation'
end

Rake::RDocTask.new do |rd|
  rd.main = 'README.rdoc'
  rd.rdoc_files.include('README.rdoc', 'lib/**/*.rb', 'bin/**/*')
  rd.title = 'Autosign'
end

CUKE_RESULTS = 'results.html'.freeze
CLEAN << CUKE_RESULTS
desc 'Run features'

Cucumber::Rake::Task.new(:features) do |t|
  t.cucumber_opts = 'features --format pretty'
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
  t.libs << 'test'
  t.test_files = FileList['test/*_test.rb']
end

task :ci => [:spec, :features]

task :default => [:test, :features]
