require 'spec_helper'
require_relative 'sharedcontext'
require_relative 'shared_expectations'
require 'vagrant-r10k/action/base'
require 'vagrant-r10k/action/deploy'

include SharedExpectations

describe VagrantPlugins::R10k::Action::Deploy do

  subject { described_class.new(app, env) }

  include_context 'vagrant-unit'

  describe '#call' do
    describe 'r10k not enabled' do
      let(:pf_dbl) { double }
      before do
        allow_any_instance_of(VagrantPlugins::R10k::Helpers).to receive(:r10k_enabled?).and_return(false)
        allow_any_instance_of(VagrantPlugins::R10k::Helpers).to receive(:provision_enabled?).and_return(true)
        allow_any_instance_of(VagrantPlugins::R10k::Helpers).to receive(:r10k_config).with(env).and_return({:puppetfile_path => 'p'})
        allow_any_instance_of(VagrantPlugins::R10k::Helpers).to receive(:get_puppetfile).and_return(pf_dbl)
      end
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
        # positive assertions
        expect_any_instance_of(VagrantPlugins::R10k::Helpers).to receive(:r10k_enabled?).with(env).once
        expect(ui).to receive(:info).with("vagrant-r10k not configured; skipping").once
        expect(app).to receive(:call).once.with(env)
        # negative assetions
        expect_any_instance_of(VagrantPlugins::R10k::Helpers).to_not receive(:provision_enabled?)
        expect(ui).to_not receive(:info).with(/Beginning r10k deploy/)
        expect(subject).to receive(:deploy).exactly(0).times
        # run
        expect(subject.call(env)).to be_nil
      end
    end

    describe 'provisioning not enabled' do
      let(:pf_dbl) { double }
      before do
        allow_any_instance_of(VagrantPlugins::R10k::Helpers).to receive(:r10k_enabled?).and_return(true)
        allow_any_instance_of(VagrantPlugins::R10k::Helpers).to receive(:provision_enabled?).and_return(false)
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
      it 'should send ui info and return' do
        # positive assertions
        expect_any_instance_of(VagrantPlugins::R10k::Helpers).to receive(:r10k_enabled?).with(env).once
        expect_any_instance_of(VagrantPlugins::R10k::Helpers).to receive(:provision_enabled?).with(env).once
        expect(ui).to receive(:info).with("provisioning disabled; skipping vagrant-r10k").once
        expect(app).to receive(:call).once.with(env)
        # negative assetions
        expect_any_instance_of(VagrantPlugins::R10k::Helpers).to_not receive(:r10k_config)
        expect(ui).to_not receive(:info).with(/Beginning r10k deploy/)
        expect(subject).to receive(:deploy).exactly(0).times
        # run
        expect(subject.call(env)).to be_nil
      end
    end

    describe 'config is nil' do
      let(:pf_dbl) { double }
      before do
        allow_any_instance_of(VagrantPlugins::R10k::Helpers).to receive(:r10k_enabled?).and_return(true)
        allow_any_instance_of(VagrantPlugins::R10k::Helpers).to receive(:provision_enabled?).and_return(true)
        allow_any_instance_of(VagrantPlugins::R10k::Helpers).to receive(:r10k_config).with(env).and_return(nil)
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
      it 'should raise exception' do
        # positive assertions
        expect_any_instance_of(VagrantPlugins::R10k::Helpers).to receive(:r10k_enabled?).with(env).once
        expect_any_instance_of(VagrantPlugins::R10k::Helpers).to receive(:provision_enabled?).with(env).once
        expect_any_instance_of(VagrantPlugins::R10k::Helpers).to receive(:r10k_config).with(env).once
        logger = subject.instance_variable_get(:@logger)
        expect(logger).to receive(:info).once.with("vagrant::r10k::deploy got nil configuration")
        expect(app).to_not receive(:call)
        # negative assetions
        expect_any_instance_of(VagrantPlugins::R10k::Helpers).to_not receive(:r10k_config)
        expect(ui).to_not receive(:info).with(/Beginning r10k deploy/)
        expect(subject).to receive(:deploy).exactly(0).times
        # run
        expect { subject.call(env) }.to raise_error(VagrantPlugins::R10k::Helpers::ErrorWrapper, /vagrant-r10k configuration error; cannot continue/)
      end
    end
    describe 'config properly set' do
      # TODO this is a *GOOD* example of testing a method...
      let(:config) {{
                      :env_dir_path => 'env/dir/path',
                      :puppetfile_path => 'puppetfile/path',
                      :module_path => 'module/path',
                      :manifests => 'manifests',
                      :manifest_file => 'manifest/file',
                      :puppet_dir => 'puppet/dir',
                    }}
      before do
        allow_any_instance_of(VagrantPlugins::R10k::Helpers).to receive(:provision_enabled?).and_return(true)
        allow_any_instance_of(VagrantPlugins::R10k::Helpers).to receive(:r10k_config).with(env).and_return(config)
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
      it 'should call deploy' do
        allow(subject).to receive(:deploy).with(env, config).and_return(true).once
        expect_any_instance_of(VagrantPlugins::R10k::Helpers).to receive(:provision_enabled?).with(env).once
        expect_any_instance_of(VagrantPlugins::R10k::Helpers).to receive(:r10k_config).with(env).once
        logger = subject.instance_variable_get(:@logger)
        expect(logger).to receive(:debug).once.ordered.with("vagrant::r10k::deploy called")
        expect(logger).to receive(:debug).once.ordered.with("vagrant::r10k::deploy: env_dir_path=env/dir/path")
        expect(logger).to receive(:debug).once.ordered.with("vagrant::r10k::deploy: puppetfile_path=puppetfile/path")
        expect(logger).to receive(:debug).once.ordered.with("vagrant::r10k::deploy: module_path=module/path")
        expect(logger).to receive(:debug).once.ordered.with("vagrant::r10k::deploy: manifests=manifests")
        expect(logger).to receive(:debug).once.ordered.with("vagrant::r10k::deploy: manifest_file=manifest/file")
        expect(logger).to receive(:debug).once.ordered.with("vagrant::r10k::deploy: puppet_dir=puppet/dir")
        expect(subject).to receive(:deploy).with(env, config).once
        expect(app).to receive(:call).once.with(env)
        expect(subject.call(env)).to be_nil
      end
    end
  end # end #call
end
