require 'bundler/gem_tasks'
require 'rubygems'
require 'bundler/setup'
Bundler::GemHelper.install_tasks

task :default => [:help]

desc "Display the list of available rake tasks"
task :help do
  system("rake -T")
end
