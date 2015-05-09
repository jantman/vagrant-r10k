require 'pathname'
require "vagrant-spec/acceptance"
require 'rspec_junit_formatter'

Vagrant::Spec::Acceptance.configure do |c|
  acceptance_dir = Pathname.new File.expand_path("../spec/acceptance", __FILE__)
  c.component_paths = [acceptance_dir.to_s]
  c.skeleton_paths = [(acceptance_dir + 'skeletons').to_s]
  c.rspec_args_append = [
    '--format',
    'RspecJunitFormatter',
    '--out',
    'results.xml',
  ]

  c.provider ENV['VS_PROVIDER'], box: ENV['VS_BOX_PATH'], skeleton_path: c.skeleton_paths
end
