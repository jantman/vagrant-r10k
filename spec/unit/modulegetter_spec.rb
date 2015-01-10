require 'spec_helper'
require_relative 'sharedcontext'
require_relative 'shared_expectations'

require 'r10k/puppetfile'
require 'r10k/task_runner'
require 'r10k/task/puppetfile'
require 'vagrant-r10k/modulegetter'

include SharedExpectations

describe Log4r::Logger do
  subject { described_class.new('testlogger') }
  describe '#debug1' do
    it 'should pass through to debug' do
      expect(subject).to receive(:debug).with('a message').once
      subject.debug1('a message')
    end
  end
  describe '#debug2' do
    it 'should pass through to debug' do
      expect(subject).to receive(:debug).with('different message').once
      subject.debug2('different message')
    end
  end 
end

describe R10K::TaskRunner do
  subject { described_class.new({}) }
  describe '#get_errors' do
    it 'returns @errors' do
      subject.instance_variable_set(:@errors, ['foo'])
      expect(subject).to receive(:get_errors).once.and_call_original
      foo = subject.get_errors
      expect(foo).to eq(['foo'])
    end
  end
end

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
        File.stub(:join).and_call_original
        File.stub(:join).with('/rootpath', 'puppet/Puppetfile').and_return('foobarbaz')
        expect(File).to receive(:join).with('/rootpath', 'puppet/Puppetfile').exactly(0).times
        expect_did_not_run(ui, app, env)
        
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
        File.stub(:join).and_call_original
        File.stub(:join).with('/rootpath', 'puppet/Puppetfile').and_return('foobarbaz')
        expect(File).to receive(:join).with('/rootpath', 'puppet/Puppetfile').exactly(0).times
        expect_did_not_run(ui, app, env)
        
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
        File.stub(:file?).with('/rootpath/puppet/Puppetfile').and_return(true)
        expect(File).to receive(:join).with('/rootpath', 'default.pp').exactly(0).times
        expect_did_not_run(ui, app, env)
        
        retval = subject.call(env)
        expect(retval).to be_nil
      end
    end
    describe 'r10k module_path set differently from puppet array' do
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
    puppet.module_path = ["puppet/modules", "foo/modules"]
  end
end
EOF
        }
      end
      it 'should raise an error' do
        expect(ui).to receive(:detail).with("vagrant-r10k: module_path \"mymodulepath/foo\" is not within the ones defined in puppet provisioner; not running").once
        File.stub(:file?).with('/rootpath/puppet/Puppetfile').and_return(true)
        expect(File).to receive(:join).with('/rootpath', 'default.pp').exactly(0).times
        expect_did_not_run(ui, app, env)
        
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
        expect_ran_successfully({:ui => ui,
                                 :subject => subject,
                                 :module_path => 'puppet/modules',
                                 :puppetfile_path => 'puppet/Puppetfile',
                                 :rootpath => '/rootpath',
                                 :puppet_dir => 'puppet',
                                })
        retval = subject.call(env)
        expect(retval).to be_nil
      end
    end
    describe 'vagrant normal logging' do
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
      it 'should set r10k normal logging' do
        expect_ran_successfully({:ui => ui,
                                 :subject => subject,
                                 :module_path => 'puppet/modules',
                                 :puppetfile_path => 'puppet/Puppetfile',
                                 :rootpath => '/rootpath',
                                 :puppet_dir => 'puppet',
                                })
        retval = subject.call(env)
        expect(R10K::Logging.level).to eq(3)
        expect(retval).to be_nil
      end
    end
    describe 'vagrant debug logging' do
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
      it 'should set r10k debug logging' do
        expect_ran_successfully({:ui => ui,
                                 :subject => subject,
                                 :module_path => 'puppet/modules',
                                 :puppetfile_path => 'puppet/Puppetfile',
                                 :rootpath => '/rootpath',
                                 :puppet_dir => 'puppet',
                                })
        with_temp_env("VAGRANT_LOG" => "debug") do
          retval = subject.call(env)
          expect(R10K::Logging.level).to eq(0)
          expect(retval).to be_nil
        end
      end
    end
    describe 'puppetfile does not exist' do
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
      it 'raise an error' do
        File.stub(:file?).with('/rootpath/puppet/Puppetfile').and_return(false)
        expect(ui).to receive(:info).with(/Building the r10k module path with puppet provisioner module_path/).once
        expect(ui).to receive(:info).with(/Beginning r10k deploy/).once
        expect_did_not_run(ui, app, env, nobegin=false, appcall=false)
        expect{subject.call(env)}.to raise_error(VagrantPlugins::R10k::ErrorWrapper, "RuntimeError: Puppetfile at /rootpath/puppet/Puppetfile does not exist.")
      end
    end
    describe 'puppetfile syntax error' do
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
      it 'raise an error' do
        File.stub(:file?).with('/rootpath/puppet/Puppetfile').and_return(true)
        expect(ui).to receive(:info).with(/Building the r10k module path with puppet provisioner module_path/).once
        expect(ui).to receive(:info).with("vagrant-r10k: Building the r10k module path with puppet provisioner module_path \"puppet/modules\". (if module_path is an array, first element is used)").exactly(0).times
        full_puppetfile_path = File.join('/rootpath', 'puppet/Puppetfile')
        full_puppet_dir = File.join('/rootpath', 'puppet')
        full_module_path = File.join('/rootpath', 'puppet/modules')
        File.stub(:file?).with(full_puppetfile_path).and_return(true)
        File.stub(:readable?).with(full_puppetfile_path).and_return(true)
        File.stub(:read).with(full_puppetfile_path).and_return("mod 'branan/eight_hundred' :git => 'https://github.com/branan/eight_hundred'")
        errmsg = /SyntaxError: \/rootpath\/puppet\/Puppetfile:1: syntax error, unexpected ':', expecting end-of-input/
        expect(ui).to receive(:info).with(/Beginning r10k deploy/).once
        expect(ui).to receive(:info).with('vagrant-r10k: Deploy finished').exactly(0).times
        expect(ui).to receive(:error).with('Invalid syntax in Puppetfile at /rootpath/puppet/Puppetfile').exactly(1).times
        expect{subject.call(env)}.to raise_error(VagrantPlugins::R10k::ErrorWrapper, errmsg)
      end
    end
    describe 'runner failed' do
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
      it 'raise an error' do
        File.stub(:file?).with('/rootpath/puppet/Puppetfile').and_return(true)
        expect(ui).to receive(:info).with(/Building the r10k module path with puppet provisioner module_path/).once
        expect(ui).to receive(:info).with("vagrant-r10k: Building the r10k module path with puppet provisioner module_path \"puppet/modules\". (if module_path is an array, first element is used)").exactly(0).times
        full_puppetfile_path = File.join('/rootpath', 'puppet/Puppetfile')
        full_puppet_dir = File.join('/rootpath', 'puppet')
        full_module_path = File.join('/rootpath', 'puppet/modules')
        File.stub(:file?).with(full_puppetfile_path).and_return(true)
        File.stub(:readable?).with(full_puppetfile_path).and_return(true)
        File.stub(:read).with(full_puppetfile_path).and_return("mod 'puppetlabs/apache'")
        expect(ui).to receive(:info).with(/Beginning r10k deploy/).once
        runner = R10K::TaskRunner.new([])
        R10K::TaskRunner.stub(:new).and_return(runner)
        R10K::TaskRunner.stub(:append_task).and_call_original
        runner.stub(:run)
        runner.stub(:succeeded?).and_return(false)
        runner.stub(:get_errors).and_return([['foo', 'this is an error']])
        expect(runner).to receive(:append_task).once
        expect(runner).to receive(:run).once
        expect(ui).to receive(:info).with('vagrant-r10k: Deploy finished').exactly(0).times
        expect{subject.call(env)}.to raise_error(VagrantPlugins::R10k::ErrorWrapper, /this is an error/)
      end
    end

    
  end
end
