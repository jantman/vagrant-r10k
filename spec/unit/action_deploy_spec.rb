require 'spec_helper'
require_relative 'sharedcontext'
require_relative 'shared_expectations'
require 'vagrant-r10k/action/base'
require 'vagrant-r10k/action/deploy'
require 'r10k/task/puppetfile'
require 'r10k/git/errors'
require 'r10k/errors'

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
        # positive expectations
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
        # positive expectations
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
        # positive expectations
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
      let(:config) {{
                      :env_dir_path => 'env/dir/path',
                      :puppetfile_path => 'puppetfile/path',
                      :module_path => 'module/path',
                      :manifests => 'manifests',
                      :manifest_file => 'manifest/file',
                      :puppet_dir => 'puppet/dir',
                    }}
      let(:pf_dbl) { double }
      before do
        allow_any_instance_of(VagrantPlugins::R10k::Helpers).to receive(:r10k_enabled?).and_return(true)
        allow_any_instance_of(VagrantPlugins::R10k::Helpers).to receive(:provision_enabled?).and_return(true)
        allow_any_instance_of(VagrantPlugins::R10k::Helpers).to receive(:r10k_config).with(env).and_return(config)
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
      it 'should call deploy' do
        # positive expectations
        allow(subject).to receive(:deploy).with(env, config).and_return(true).once
        expect_any_instance_of(VagrantPlugins::R10k::Helpers).to receive(:r10k_enabled?).with(env).once
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
        # run
        expect(subject.call(env)).to be_nil
      end
    end
  end # end #call

  describe '#deploy' do
    let(:config) {{
                    :env_dir_path => 'env/dir/path',
                    :puppetfile_path => 'puppetfile/path',
                    :module_path => 'module/path',
                    :manifests => 'manifests',
                    :manifest_file => 'manifest/file',
                    :puppet_dir => 'puppet/dir',
                  }}
    describe 'successful run' do
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
      let(:puppetfile_dbl) { double }
      before do
        allow_any_instance_of(VagrantPlugins::R10k::Helpers).to receive(:get_puppetfile).and_return(puppetfile_dbl)
        allow_any_instance_of(R10K::Logging).to receive(:level=)
      end
      it 'runs' do
        # stubs and doubles
        with_temp_env("VAGRANT_LOG" => "foo") do
          File.stub(:file?).with('puppetfile/path').and_return(true)
          runner_dbl = double
          sync_dbl = double
          allow(runner_dbl).to receive(:append_task).with(sync_dbl)
          allow(runner_dbl).to receive(:succeeded?).and_return(true)
          allow(sync_dbl).to receive(:new).with(puppetfile_dbl)
          R10K::TaskRunner.stub(:new) { runner_dbl }
          R10K::Task::Puppetfile::Sync.stub(:new) { sync_dbl }
          # expectations
          expect(R10K::Logging).to receive(:level=).with('info').twice
          expect(ui).to receive(:info).with("vagrant-r10k: Beginning r10k deploy of puppet modules into module/path using puppetfile/path")
          logger = subject.instance_variable_get(:@logger)
          expect(logger).to receive(:debug).once.ordered.with("vagrant::r10k::deploy.deploy called")
          expect(logger).to receive(:debug).once.ordered.with("vagrant-r10k: creating Puppetfile::Sync task")
          expect(logger).to receive(:debug).once.ordered.with("vagrant-r10k: appending task to runner queue")
          expect(runner_dbl).to receive(:append_task).with(sync_dbl).once
          expect(logger).to receive(:debug).once.ordered.with("vagrant-r10k: running sync task")
          expect(runner_dbl).to receive(:run).once
          expect(logger).to receive(:debug).once.ordered.with("vagrant-r10k: sync task complete")
          expect(runner_dbl).to receive(:succeeded?).once
          expect(ui).to receive(:info).with("vagrant-r10k: Deploy finished")
          expect(app).to receive(:call).once.with(env)
          # run
          expect(subject.deploy(env, config)).to be_nil
        end
      end
    end

    describe 'successful run with debug' do
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
      let(:puppetfile_dbl) { double }
      before do
        allow_any_instance_of(VagrantPlugins::R10k::Helpers).to receive(:get_puppetfile).and_return(puppetfile_dbl)
        allow_any_instance_of(R10K::Logging).to receive(:level=)
      end
      it 'runs with r10k logging level to 0' do
        # stubs and doubles
        with_temp_env("VAGRANT_LOG" => "debug") do
          File.stub(:file?).with('puppetfile/path').and_return(true)
          runner_dbl = double
          sync_dbl = double
          allow(runner_dbl).to receive(:append_task).with(sync_dbl)
          allow(runner_dbl).to receive(:succeeded?).and_return(true)
          allow(sync_dbl).to receive(:new).with(puppetfile_dbl)
          R10K::TaskRunner.stub(:new) { runner_dbl }
          R10K::Task::Puppetfile::Sync.stub(:new) { sync_dbl }
          # expectations
          expect(R10K::Logging).to receive(:level=).with('debug').twice
          expect(ui).to receive(:info).with("vagrant-r10k: Beginning r10k deploy of puppet modules into module/path using puppetfile/path")
          logger = subject.instance_variable_get(:@logger)
          expect(logger).to receive(:debug).once.ordered.with("vagrant::r10k::deploy.deploy called")
          expect(logger).to receive(:debug).once.ordered.with("vagrant-r10k: creating Puppetfile::Sync task")
          expect(logger).to receive(:debug).once.ordered.with("vagrant-r10k: appending task to runner queue")
          expect(runner_dbl).to receive(:append_task).with(sync_dbl).once
          expect(logger).to receive(:debug).once.ordered.with("vagrant-r10k: running sync task")
          expect(runner_dbl).to receive(:run).once
          expect(logger).to receive(:debug).once.ordered.with("vagrant-r10k: sync task complete")
          expect(runner_dbl).to receive(:succeeded?).once
          expect(ui).to receive(:info).with("vagrant-r10k: Deploy finished")
          expect(app).to receive(:call).once.with(env)
          # run
          expect(subject.deploy(env, config)).to be_nil
        end
      end
    end

    describe 'puppetfile doesnt exist' do
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
      let(:puppetfile_dbl) { double }
      before do
        allow_any_instance_of(VagrantPlugins::R10k::Helpers).to receive(:get_puppetfile).and_return(puppetfile_dbl)
      end
      it 'raises an error' do
        # stubs and doubles
        with_temp_env("VAGRANT_LOG" => "none") do
          File.stub(:file?).with('puppetfile/path').and_return(false)
          runner_dbl = double
          sync_dbl = double
          allow(runner_dbl).to receive(:append_task).with(sync_dbl)
          allow(runner_dbl).to receive(:succeeded?).and_return(true)
          allow(sync_dbl).to receive(:new).with(puppetfile_dbl)
          R10K::TaskRunner.stub(:new) { runner_dbl }
          R10K::Task::Puppetfile::Sync.stub(:new) { sync_dbl }
          # expectations
          expect(ui).to receive(:info).with("vagrant-r10k: Beginning r10k deploy of puppet modules into module/path using puppetfile/path")
          logger = subject.instance_variable_get(:@logger)
          # negative expectations
          expect(logger).to_not receive(:debug).once.ordered.with("vagrant::r10k::deploy.deploy called")
          expect(logger).to_not receive(:debug).with("vagrant-r10k: creating Puppetfile::Sync task")
          expect(logger).to_not receive(:debug).with("vagrant-r10k: appending task to runner queue")
          expect(runner_dbl).to_not receive(:append_task).with(sync_dbl)
          expect(logger).to_not receive(:debug).with("vagrant-r10k: running sync task")
          expect(runner_dbl).to_not receive(:run)
          expect(logger).to_not receive(:debug).with("vagrant-r10k: sync task complete")
          expect(runner_dbl).to_not receive(:succeeded?)
          expect(ui).to_not receive(:info).with("vagrant-r10k: Deploy finished")
          expect(app).to_not receive(:call).with(env)
          # run
          expect { subject.deploy(env, config) }.to raise_error(VagrantPlugins::R10k::Helpers::ErrorWrapper, /Puppetfile at puppetfile\/path does not exist/)
        end
      end
    end

    describe 'run failed' do
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
      let(:puppetfile_dbl) { double }
      before do
        allow_any_instance_of(VagrantPlugins::R10k::Helpers).to receive(:get_puppetfile).and_return(puppetfile_dbl)
        allow_any_instance_of(R10K::Logging).to receive(:level=)
      end
      it 'raises an error' do
        # stubs and doubles
        with_temp_env("VAGRANT_LOG" => "foo") do
          File.stub(:file?).with('puppetfile/path').and_return(true)
          runner_dbl = double
          sync_dbl = double
          allow(runner_dbl).to receive(:append_task).with(sync_dbl)
          allow(runner_dbl).to receive(:succeeded?).and_return(false)
          allow(runner_dbl).to receive(:get_errors).and_return(
                                 [[
                                   sync_dbl,
                                   R10K::Git::GitError.new("Couldn't update git cache for https://example.com/foobar.git: \"fatal: repository 'https://example.com/foobar.git/' not found\"")
                                 ]])
          allow(sync_dbl).to receive(:new).with(puppetfile_dbl)
          R10K::TaskRunner.stub(:new) { runner_dbl }
          R10K::Task::Puppetfile::Sync.stub(:new) { sync_dbl }
          # expectations
          expect(R10K::Logging).to receive(:level=).with('info').twice
          expect(ui).to receive(:info).with("vagrant-r10k: Beginning r10k deploy of puppet modules into module/path using puppetfile/path")
          logger = subject.instance_variable_get(:@logger)
          expect(logger).to receive(:debug).once.ordered.with("vagrant::r10k::deploy.deploy called")
          expect(logger).to receive(:debug).once.ordered.with("vagrant-r10k: creating Puppetfile::Sync task")
          expect(logger).to receive(:debug).once.ordered.with("vagrant-r10k: appending task to runner queue")
          expect(runner_dbl).to receive(:append_task).with(sync_dbl).once
          expect(logger).to receive(:debug).once.ordered.with("vagrant-r10k: running sync task")
          expect(runner_dbl).to receive(:run).once
          expect(logger).to receive(:debug).once.ordered.with("vagrant-r10k: sync task complete")
          expect(runner_dbl).to receive(:succeeded?).once
          # negative expectations
          expect(ui).to_not receive(:info).with("vagrant-r10k: Deploy finished")
          expect(app).to_not receive(:call)
          # run
          expect { subject.deploy(env, config) }.to raise_error(VagrantPlugins::R10k::Helpers::ErrorWrapper, /Couldn't update git cache for https:\/\/example\.com\/foobar\.git: "fatal: repository 'https:\/\/example\.com\/foobar\.git\/' not found"/)
        end
      end
    end

    describe 'Could not resolve host' do
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
      let(:puppetfile_dbl) { double }
      before do
        allow_any_instance_of(VagrantPlugins::R10k::Helpers).to receive(:get_puppetfile).and_return(puppetfile_dbl)
        allow_any_instance_of(R10K::Logging).to receive(:level=)
      end
      it 'raises an error' do
        # stubs and doubles
        with_temp_env("VAGRANT_LOG" => "foo") do
          File.stub(:file?).with('puppetfile/path').and_return(true)
          runner_dbl = double
          sync_dbl = double
          allow(runner_dbl).to receive(:append_task).with(sync_dbl)
          allow(runner_dbl).to receive(:succeeded?).and_return(false)
          allow(runner_dbl).to receive(:get_errors).and_return(
                                 [[
                                   sync_dbl,
                                   R10K::Git::GitError.new("Couldn't update git cache for https://foo.com/jantman/bar.git: \"fatal: unable to access 'https://foo.com/jantman/bar.git/': Could not resolve host: foo.com\"")
                                 ]])
          allow(sync_dbl).to receive(:new).with(puppetfile_dbl)
          R10K::TaskRunner.stub(:new) { runner_dbl }
          R10K::Task::Puppetfile::Sync.stub(:new) { sync_dbl }
          # expectations
          expect(R10K::Logging).to receive(:level=).with('info').twice
          expect(ui).to receive(:info).with("vagrant-r10k: Beginning r10k deploy of puppet modules into module/path using puppetfile/path")
          logger = subject.instance_variable_get(:@logger)
          expect(logger).to receive(:debug).once.ordered.with("vagrant::r10k::deploy.deploy called")
          expect(logger).to receive(:debug).once.ordered.with("vagrant-r10k: creating Puppetfile::Sync task")
          expect(logger).to receive(:debug).once.ordered.with("vagrant-r10k: appending task to runner queue")
          expect(runner_dbl).to receive(:append_task).with(sync_dbl).once
          expect(logger).to receive(:debug).once.ordered.with("vagrant-r10k: running sync task")
          expect(runner_dbl).to receive(:run).once
          expect(logger).to receive(:debug).once.ordered.with("vagrant-r10k: sync task complete")
          expect(logger).to receive(:debug).once.ordered.with("vagrant-r10k: caught 'Could not resolve host' error")
          expect(runner_dbl).to receive(:succeeded?).once
          # negative expectations
          expect(ui).to_not receive(:info).with("vagrant-r10k: Deploy finished")
          expect(app).to_not receive(:call)
          # run
          expect { subject.deploy(env, config) }.to raise_error(VagrantPlugins::R10k::Helpers::ErrorWrapper, /Could not resolve host: foo\.com.*If you don't have connectivity to the host, running 'vagrant up --no-provision' will skip r10k deploy and all provisioning/m)
        end
      end
    end

    describe 'puppetfile syntax error' do
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
      let(:puppetfile_dbl) { double }
      before do
        allow_any_instance_of(VagrantPlugins::R10k::Helpers).to receive(:get_puppetfile).and_return(puppetfile_dbl)
        allow_any_instance_of(R10K::Logging).to receive(:level=)
      end
      it 'raises an error' do
        # stubs and doubles
        with_temp_env("VAGRANT_LOG" => "foo") do
          File.stub(:file?).with('puppetfile/path').and_return(true)
          runner_dbl = double
          sync_dbl = double
          allow(runner_dbl).to receive(:append_task).with(sync_dbl)
          allow(runner_dbl).to receive(:succeeded?).and_return(false)
          orig = SyntaxError.new("some syntax error")
          ex = R10K::Error.wrap(orig, 'message')
          allow(runner_dbl).to receive(:run).and_raise(ex)
          allow(sync_dbl).to receive(:new).with(puppetfile_dbl)
          R10K::TaskRunner.stub(:new) { runner_dbl }
          R10K::Task::Puppetfile::Sync.stub(:new) { sync_dbl }
          # expectations
          expect(R10K::Logging).to receive(:level=).with('info').twice
          expect(ui).to receive(:info).with("vagrant-r10k: Beginning r10k deploy of puppet modules into module/path using puppetfile/path")
          logger = subject.instance_variable_get(:@logger)
          expect(logger).to receive(:debug).once.ordered.with("vagrant::r10k::deploy.deploy called")
          expect(logger).to receive(:debug).once.ordered.with("vagrant-r10k: creating Puppetfile::Sync task")
          expect(logger).to receive(:debug).once.ordered.with("vagrant-r10k: appending task to runner queue")
          expect(runner_dbl).to receive(:append_task).with(sync_dbl).once
          expect(logger).to receive(:debug).once.ordered.with("vagrant-r10k: running sync task")
          expect(runner_dbl).to receive(:run).once
          # negative expectations
          expect(logger).to_not receive(:debug).with("vagrant-r10k: sync task complete")
          expect(runner_dbl).to_not receive(:succeeded?)
          expect(ui).to_not receive(:info).with("vagrant-r10k: Deploy finished")
          expect(app).to_not receive(:call)
          # run
          expect { subject.deploy(env, config) }.to raise_error(VagrantPlugins::R10k::Helpers::ErrorWrapper, /SyntaxError: some syntax error/)
        end
      end
    end
  end
end
