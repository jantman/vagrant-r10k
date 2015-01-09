require 'spec_helper'

require 'vagrant-r10k/config'

describe VagrantPlugins::R10k::Config do
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

  context 'when validated' do
    before(:each) { subject.finalize! }
    describe 'with puppet_dir and puppetfile_path unset' do
      it 'passes validation' do
        errors = subject.validate(machine)
        errors.should eq({})
      end
    end

    describe 'with puppet_dir unset' do
      it 'fails validation' do
        subject.puppetfile_path = '/foo/bar'
        errors = subject.validate(machine)
        errors.should eq({"vagrant-r10k"=>["config.r10k.puppet_dir must be set"]})
      end
    end

    describe 'when puppet_dir does not exist' do
      it 'fails validation' do
        puppetfile = '/foo/bar'
        puppet_dir = '/baz/blam'
        puppetfile_path = File.join(env.root_path, puppetfile)
        puppet_dir_path = File.join(env.root_path, puppet_dir)

        subject.puppetfile_path = puppetfile
        subject.puppet_dir = puppet_dir

        # stub only for the checks we care about
        File.stub(:file?).and_call_original
        File.stub(:file?).with(puppetfile_path).and_return(true)
        File.stub(:directory?).and_call_original
        File.stub(:directory?).with(puppet_dir_path).and_return(false)
        errors = subject.validate(machine)
        errors.should eq({"vagrant-r10k"=>["puppet_dir directory '#{puppet_dir_path}' does not exist"]})
      end
    end

    describe 'with puppetfile_path unset' do
      it 'fails validation' do
        puppet_dir = '/baz/blam'
        puppet_dir_path = File.join(env.root_path, puppet_dir)

        subject.puppet_dir = puppet_dir

        # stub File.directory? only for /baz/blam
        File.stub(:directory?).and_call_original
        File.stub(:directory?).with(puppet_dir_path).and_return(true)
        errors = subject.validate(machine)
        errors.should eq({"vagrant-r10k"=>["config.r10k.puppetfile_path must be set"]})
      end
    end

    describe 'when puppetfile_path does not exist' do
      it 'fails validation' do
        puppetfile = '/foo/bar'
        puppet_dir = '/baz/blam'
        puppetfile_path = File.join(env.root_path, puppetfile)
        puppet_dir_path = File.join(env.root_path, puppet_dir)

        subject.puppetfile_path = puppetfile
        subject.puppet_dir = puppet_dir

        # stub only for the checks we care about
        File.stub(:file?).and_call_original
        File.stub(:file?).with(puppetfile_path).and_return(false)
        File.stub(:directory?).and_call_original
        File.stub(:directory?).with(puppet_dir_path).and_return(true)
        errors = subject.validate(machine)
        errors.should eq({"vagrant-r10k"=>["puppetfile '#{puppetfile_path}' does not exist"]})
      end
    end

    describe 'if module_path specified but does not exist' do
      it 'fails validation' do
        puppetfile = '/foo/bar'
        puppet_dir = '/baz/blam'
        module_path = '/blarg/modules'
        puppetfile_path = File.join(env.root_path, puppetfile)
        puppet_dir_path = File.join(env.root_path, puppet_dir)
        module_path_path = File.join(env.root_path, module_path)

        subject.puppetfile_path = puppetfile
        subject.puppet_dir = puppet_dir
        subject.module_path = module_path

        # stub only for the checks we care about
        File.stub(:file?).and_call_original
        File.stub(:file?).with(puppetfile_path).and_return(true)
        File.stub(:directory?).and_call_original
        File.stub(:directory?).with(puppet_dir_path).and_return(true)
        File.stub(:directory?).with(module_path_path).and_return(false)
        errors = subject.validate(machine)
        errors.should eq({"vagrant-r10k"=>["module_path directory '#{module_path_path}' does not exist"]})
      end
    end

    describe 'if module_path specified and exists' do
      it 'passes validation' do
        puppetfile = '/foo/bar'
        puppet_dir = '/baz/blam'
        module_path = '/blarg/modules'
        puppetfile_path = File.join(env.root_path, puppetfile)
        puppet_dir_path = File.join(env.root_path, puppet_dir)
        module_path_path = File.join(env.root_path, module_path)

        subject.puppetfile_path = puppetfile
        subject.puppet_dir = puppet_dir
        subject.module_path = module_path

        # stub only for the checks we care about
        File.stub(:file?).and_call_original
        File.stub(:file?).with(puppetfile_path).and_return(true)
        File.stub(:directory?).and_call_original
        File.stub(:directory?).with(puppet_dir_path).and_return(true)
        File.stub(:directory?).with(module_path_path).and_return(true)
        errors = subject.validate(machine)
        errors.should eq({"vagrant-r10k"=>[]})
      end
    end
  end
end
