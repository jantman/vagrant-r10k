require 'bundler/gem_tasks'
require 'rubygems'
require 'bundler/setup'
Bundler::GemHelper.install_tasks

task :default => [:help]

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
end

def system_or_die(cmd, fail_msg=nil)
  puts "running: '#{cmd}'"
  res = system(cmd)
  if ! res
    if fail_msg.nil?
      $stderr.puts "Command exited non-zero: #{cmd}"
    else
      $stderr.puts fail_msg
    end
    exit!(1)
  end
end

def get_box_path(provider)
  boxes_dir = File.join(File.dirname(__FILE__), 'spec', 'boxes')
  Dir.mkdir(boxes_dir) if not File.directory?(boxes_dir)
  if provider == 'virtualbox'
    boxurl = 'https://s3.amazonaws.com/puppetlabs-vagrantcloud/centos-7.0-x86_64-virtualbox-puppet-1.0.1.box'
  elsif provider == 'aws'
    boxurl = 'https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box'
  else
    STDERR.puts "ERROR: no box URL known for provider '#{provider}'"
    exit!(1)
  end
  box_path = File.join(boxes_dir, "dummy_#{provider}.box")
  if File.exist?(box_path)
    puts "#{provider} box exists at #{box_path}"
  else
    puts "Downloading #{provider} box from #{boxurl} to #{box_path}"
    system_or_die("curl -o #{box_path} '#{boxurl}'")
  end
  return box_path
end

desc "Display the list of available rake tasks"
task :help do
  system("rake -T")
end

namespace :acceptance do
  providers = ['virtualbox', 'aws']
  all_provider_tasks = providers.map { |prov| "acceptance:#{prov}" }

  # isolate our temp directories so we can easily remove them
  tmp_dir_path = '/tmp/vagrant-r10k-spec'
  Dir.mkdir(tmp_dir_path) unless Dir.exists?(tmp_dir_path)

  providers.each do |prov|
    desc "Run acceptance tests for #{prov}"
    task prov do |task|
      provider = task.name.split(':')[1]
      puts "Running acceptance tests for #{provider}"
      box_path = get_box_path(provider)
      system_or_die("VS_PROVIDER=#{provider} VS_BOX_PATH=#{box_path} TMPDIR=#{tmp_dir_path} bundle exec vagrant-spec test")
    end
  end

  desc "Run acceptance tests for **ALL** providers"
  task :all => all_provider_tasks
end
