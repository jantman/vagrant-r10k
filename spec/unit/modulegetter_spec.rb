require 'spec_helper'

require 'vagrant-r10k/config'

describe VagrantPlugins::R10k::Modulegetter do
  include_context 'vagrant-unit'
  let(:test_env) do
    test_env = isolated_environment
    test_env.vagrantfile <<-EOF
Vagrant.configure('2') do |config|
  config.vm.define :test
end
EOF
    test_env
  end
  let(:env)              { test_env.create_vagrant_env }
  let(:machine)          { env.machine(:test, :dummy) }

end
