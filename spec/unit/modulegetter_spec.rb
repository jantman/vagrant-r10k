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
  # Mock the communicator to prevent SSH commands for being executed.
  let(:communicator)     { double('communicator') }
  # Mock the guest operating system.
  let(:guest)            { double('guest') }
  let(:app)              { double('app') }
  
  before (:each) do
    machine.stub(:guest => guest)
    machine.stub(:communicator => communicator)
  end

  after(:each) { test_env.close }

  context 'call' do
    describe 'puppet_dir unset' do
      it 'should raise an error' do
        x = 1
        x.should == 2
      end
    end
  end
  
end
