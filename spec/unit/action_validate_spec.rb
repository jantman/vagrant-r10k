require 'spec_helper'
require_relative 'sharedcontext'
require_relative 'shared_expectations'
require 'vagrant-r10k/action/base'
require 'vagrant-r10k/action/validate'

include SharedExpectations

describe VagrantPlugins::R10k::Action::Validate do

  subject { described_class.new(app, env) }

  include_context 'vagrant-unit'

  describe '#call' do
    describe 'r10k not enabled' do
      include_context 'unit' do
        let(:vagrantfile) { <<-EOF
Vagrant.configure('2') do |config|
  config.vm.define :test
  # r10k plugin to deploy puppet modules
  # config.r10k.puppet_dir = 'puppet'
  # config.r10k.puppetfile_path = 'puppet/Puppetfile'

  # Provision the machine with the appliction
  config.vm.provision "puppet" do |puppet|
    puppet.manifests_path = "puppet/manifests"
    puppet.manifest_file  = "default.pp"
    puppet.module_path = "puppet/modules"
  end
end
EOF
        }
      end
      it 'should send ui info and return' do
        expect(ui).to receive(:info).with("vagrant-r10k not configured; skipping").once
        expect(app).to receive(:call).with(env).once
        expect(ui).to receive(:info).with(/Beginning r10k deploy/).exactly(0).times
        expect(subject.call(env)).to be_nil
      end
    end

    describe 'provisioning not enabled' do
      before { allow_any_instance_of(VagrantPlugins::R10k::Helpers).to receive(:provision_enabled?).and_return(false) }
      include_context 'unit' do
        let(:vagrantfile) { <<-EOF
Vagrant.configure('2') do |config|
  config.vm.define :test
  # r10k plugin to deploy puppet modules
  config.r10k.puppet_dir = 'puppet'
  config.r10k.puppetfile_path = 'puppet/Puppetfile'

  # Provision the machine with the appliction
  config.vm.provision "puppet" do |puppet|
    puppet.manifests_path = "puppet/manifests"
    puppet.manifest_file  = "default.pp"
    puppet.module_path = "puppet/modules"
  end
end
EOF
        }
      end
      it 'should send ui info and return' do
        expect(ui).to receive(:info).with("provisioning disabled; skipping vagrant-r10k").once
        expect(app).to receive(:call).with(env).once
        expect(ui).to receive(:info).with(/Beginning r10k deploy/).exactly(0).times
        expect(subject.call(env)).to be_nil
      end
    end

    describe 'config is nil' do
      before do
        allow_any_instance_of(VagrantPlugins::R10k::Helpers).to receive(:provision_enabled?).and_return(true)
        allow_any_instance_of(VagrantPlugins::R10k::Helpers).to receive(:r10k_config).with(env).and_return(nil)
      end
      include_context 'unit' do
        let(:vagrantfile) { <<-EOF
Vagrant.configure('2') do |config|
  config.vm.define :test
  # r10k plugin to deploy puppet modules
  config.r10k.puppet_dir = 'puppet'
  config.r10k.puppetfile_path = 'puppet/Puppetfile'

  # Provision the machine with the appliction
  config.vm.provision "puppet" do |puppet|
    puppet.manifests_path = "puppet/manifests"
    puppet.manifest_file  = "default.pp"
    puppet.module_path = "puppet/modules"
  end
end
EOF
        }
      end
      it 'should raise exception' do
        expect { described_class.new(app, env).call(env) }.to raise_error(VagrantPlugins::R10k::Helpers::ErrorWrapper, /vagrant-r10k configuration error; cannot continue/)
        expect(app).to receive(:call).with(env).exactly(0).times
      end
    end

    describe 'puppetfile passes validation' do
      let(:pf_dbl) { double }
      before do
        allow_any_instance_of(VagrantPlugins::R10k::Helpers).to receive(:provision_enabled?).and_return(true)
        allow_any_instance_of(VagrantPlugins::R10k::Helpers).to receive(:r10k_config).with(env).and_return({:puppetfile_path => 'p'})
        allow_any_instance_of(VagrantPlugins::R10k::Helpers).to receive(:get_puppetfile).and_return(pf_dbl)
      end
      include_context 'unit' do
        let(:vagrantfile) { <<-EOF
Vagrant.configure('2') do |config|
  config.vm.define :test
  # r10k plugin to deploy puppet modules
  config.r10k.puppet_dir = 'puppet'
  config.r10k.puppetfile_path = 'puppet/Puppetfile'

  # Provision the machine with the appliction
  config.vm.provision "puppet" do |puppet|
    puppet.manifests_path = "puppet/manifests"
    puppet.manifest_file  = "default.pp"
    puppet.module_path = "puppet/modules"
  end
end
EOF
        }
      end
      it 'should call app.call' do
        allow(pf_dbl).to receive(:load).exactly(1).times.and_return(true)
        expect { described_class.new(app, env).call(env) }.to be_a_kind_of(Proc)
      end
    end

    describe 'puppetfile fails validation' do
      let(:pf_dbl) { double }
      before do
        allow_any_instance_of(VagrantPlugins::R10k::Helpers).to receive(:provision_enabled?).and_return(true)
        allow_any_instance_of(VagrantPlugins::R10k::Helpers).to receive(:r10k_config).with(env).and_return({:puppetfile_path => 'p'})
        allow_any_instance_of(VagrantPlugins::R10k::Helpers).to receive(:get_puppetfile).and_return(pf_dbl)
      end
      include_context 'unit' do
        let(:vagrantfile) { <<-EOF
Vagrant.configure('2') do |config|
  config.vm.define :test
  # r10k plugin to deploy puppet modules
  config.r10k.puppet_dir = 'puppet'
  config.r10k.puppetfile_path = 'puppet/Puppetfile'

  # Provision the machine with the appliction
  config.vm.provision "puppet" do |puppet|
    puppet.manifests_path = "puppet/manifests"
    puppet.manifest_file  = "default.pp"
    puppet.module_path = "puppet/modules"
  end
end
EOF
        }
      end
      it 'should call app.call' do
        allow(pf_dbl).to receive(:load).and_raise(RuntimeError)
        expect { described_class.new(app, env).call(env) }.to raise_error(VagrantPlugins::R10k::Helpers::ErrorWrapper)
      end
    end

  end
end
