require 'spec_helper'

require 'vagrant-r10k/plugin'

describe VagrantPlugins::R10k::Plugin do
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
  let(:env)              { { env: iso_env } }
  let(:iso_env)          { test_env.create_vagrant_env ui_class: Vagrant::UI::Basic }
  let(:machine)          { iso_env.machine(:test, :dummy)  }
  # Mock the communicator to prevent SSH commands for being executed.
  let(:communicator)     { double('communicator') }
  # Mock the guest operating system.
  let(:guest)            { double('guest') }
  let(:app)              { lambda { |env| } }
  let(:plugin)           { register_plugin() }
  
  subject { described_class.new }

  before (:each) do
    machine.stub(:guest => guest)
    machine.stub(:communicator => communicator)
  end

  #after(:each) { test_env.close }
  
  describe '#call' do
    describe 'puppet_dir unset' do
      it 'should raise an error' do
        machine.config.r10k.puppetfile_path = '/foo/bar'
        #puts "############################################ env methods"
        #puts env.methods(true)
        #puts "############################################ subject methods"
        #puts subject.methods(true)
        #puts "############################################ plugin methods"
        #puts plugin.methods(true)
        x = 1
        x.should == 2
      end
    end
  end
  
end
