require 'spec_helper'
require_relative 'sharedcontext'

require 'vagrant-r10k/modulegetter'
require 'r10k/puppetfile'
require 'r10k/task_runner'
require 'r10k/task/puppetfile'

describe VagrantPlugins::R10k::Modulegetter do 
  subject { described_class.new(app, env) }

  describe '#call' do
    describe 'puppet_dir unset' do
      include_context 'unit' do
        let(:vagrantfile) { <<-EOF
Vagrant.configure('2') do |config|
  config.vm.define :test
  # r10k plugin to deploy puppet modules
  # config.r10k.puppet_dir = 'puppet'
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
      it 'should raise an error' do
        expect(ui).to receive(:detail).with("vagrant-r10k: puppet_dir and/or puppetfile_path not set in config; not running").once
        expect(app).to receive(:call).with(env).once
        File.stub(:join).and_call_original
        File.stub(:join).with('/rootpath', 'puppet/Puppetfile').and_return('foobarbaz')
        expect(File).to receive(:join).with('/rootpath', 'puppet/Puppetfile').exactly(0).times
        # expect it to not really run
        expect(ui).to receive(:info).with(/Beginning r10k deploy/).exactly(0).times
        R10K::Puppetfile.stub(:new)
        expect(R10K::Puppetfile).to receive(:new).exactly(0).times

        retval = subject.call(env)
        expect(retval).to be_nil
      end
    end
    describe 'puppetfile_path unset' do
      include_context 'unit' do
        let(:vagrantfile) { <<-EOF
Vagrant.configure('2') do |config|
  config.vm.define :test
  # r10k plugin to deploy puppet modules
  config.r10k.puppet_dir = 'puppet'
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
      it 'should raise an error' do
        expect(ui).to receive(:detail).with("vagrant-r10k: puppet_dir and/or puppetfile_path not set in config; not running").once
        expect(ui).to receive(:info).with(/Beginning r10k deploy/).exactly(0).times
        expect(app).to receive(:call).with(env).once
        File.stub(:join).and_call_original
        File.stub(:join).with('/rootpath', 'puppet/Puppetfile').and_return('foobarbaz')
        expect(File).to receive(:join).with('/rootpath', 'puppet/Puppetfile').exactly(0).times
        # expect it to not really run
        expect(ui).to receive(:info).with(/Beginning r10k deploy/).exactly(0).times
        R10K::Puppetfile.stub(:new)
        expect(R10K::Puppetfile).to receive(:new).exactly(0).times

        retval = subject.call(env)
        expect(retval).to be_nil
      end
    end
    describe 'r10k module_path set differently from puppet' do
      include_context 'unit' do
        let(:vagrantfile) { <<-EOF
Vagrant.configure('2') do |config|
  config.vm.define :test
  # r10k plugin to deploy puppet modules
  config.r10k.puppet_dir = 'puppet'
  config.r10k.puppetfile_path = 'puppet/Puppetfile'
  config.r10k.module_path = "mymodulepath/foo"

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
      it 'should raise an error' do
        expect(ui).to receive(:detail).with("vagrant-r10k: module_path \"mymodulepath/foo\" is not the same as in puppet provisioner; not running").once
        expect(app).to receive(:call).with(env).once
        File.stub(:file?).with('/rootpath/puppet/Puppetfile').and_return(true)
        expect(File).to receive(:join).with('/rootpath', 'default.pp').exactly(0).times
        # expect it to not really run
        expect(ui).to receive(:info).with(/Beginning r10k deploy/).exactly(0).times
        R10K::Puppetfile.stub(:new)
        expect(R10K::Puppetfile).to receive(:new).exactly(0).times
        
        retval = subject.call(env)
        expect(retval).to be_nil
      end
    end
    describe 'r10k module_path not set' do
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
      it 'should use the module_path from provisioner' do
        expect(ui).to receive(:info).with("vagrant-r10k: Building the r10k module path with puppet provisioner module_path \"puppet/modules\". (if module_path is an array, first element is used)").once
        File.stub(:file?).with('/rootpath/puppet/Puppetfile').and_return(true)
        expect(ui).to receive(:info).with(/Beginning r10k deploy/).once
        R10K::Puppetfile.stub(:new)
        expect(R10K::Puppetfile).to receive(:new).with('/rootpath/puppet', '/rootpath/puppet/modules', '/rootpath/puppet/Puppetfile').once
        R10K::Task::Puppetfile::Sync.stub(:new).and_call_original
        expect(R10K::Task::Puppetfile::Sync).to receive(:new).once
        runner = R10K::TaskRunner.new([])
        R10K::TaskRunner.stub(:new).and_return(runner)
        R10K::TaskRunner.stub(:append_task).and_call_original
        runner.stub(:run)
        runner.stub(:succeeded?).and_return(true)
        runner.stub(:get_errors).and_return([])
        expect(runner).to receive(:append_task).once
        expect(runner).to receive(:run).once
        expect(ui).to receive(:info).with('vagrant-r10k: Deploy finished').once
        retval = subject.call(env)
        expect(retval).to be_nil
      end
    end

    
  end
end
