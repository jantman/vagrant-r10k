require 'spec_helper'

require 'vagrant-r10k/helpers'

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
  subject { described_class.new([]) }
  describe '#get_errors' do
    it 'returns @errors' do
      subject.instance_variable_set(:@errors, ['foo'])
      expect(subject).to receive(:get_errors).once.and_call_original
      foo = subject.get_errors
      expect(foo).to eq(['foo'])
    end
  end
end

describe VagrantPlugins::R10k::Helpers::ErrorWrapper do
  describe '#initialize' do
    it 'sets instance variable' do
      foo = double
      klass = described_class.new(foo)
      expect(klass.instance_variable_get(:@original)).to eq(foo)
    end
    it 'has attr_reader' do
      foo = double
      klass = described_class.new(foo)
      expect(klass.original).to eq(foo)
    end
  end
  describe '#to_s' do
    it 'returns the proper string' do
      foo = double
      allow(foo).to receive(:class).and_return('foo')
      allow(foo).to receive(:to_s).and_return('foostr')
      klass = described_class.new(foo)
      expect(klass.to_s).to eq('foo: foostr')
    end
  end
  describe '#method_missind' do
    it 'sends to foo' do
      foo = double
      allow(foo).to receive(:bar).and_return('baz')
      foo.should_receive(:bar).once
      klass = described_class.new(foo)
      expect(klass.bar).to eq('baz')
    end
  end
end

describe VagrantPlugins::R10k::Helpers do
  include VagrantPlugins::R10k::Helpers

  describe '#r10k_enabled?' do
    context 'puppet_dir unset' do
      it 'returns false' do
        env = {:machine => double}
        env[:machine].stub_chain(:config, :r10k, :puppet_dir).and_return(Vagrant::Plugin::V2::Config::UNSET_VALUE)
        env[:machine].stub_chain(:config, :r10k, :puppetfile_path).and_return('/puppetfile/path')
        expect(r10k_enabled?(env)).to be_falsey
      end
    end
    context 'puppetfile_path unset' do
      it 'returns false' do
        env = {:machine => double}
        env[:machine].stub_chain(:config, :r10k, :puppet_dir).and_return('/puppet/dir')
        env[:machine].stub_chain(:config, :r10k, :puppetfile_path).and_return(Vagrant::Plugin::V2::Config::UNSET_VALUE)
        expect(r10k_enabled?(env)).to be_falsey
      end
    end
    context 'puppet_dir unset' do
      it 'returns false' do
        env = {:machine => double}
        env[:machine].stub_chain(:config, :r10k, :puppet_dir).and_return('/puppet/dir')
        env[:machine].stub_chain(:config, :r10k, :puppetfile_path).and_return('/puppetfile/path')
        expect(r10k_enabled?(env)).to be_truthy
      end
    end
  end

  describe '#provision_enabled?' do
    context 'env not set' do
      it 'returns true' do
        env = {}
        expect(provision_enabled?(env)).to be_truthy
      end
    end
    context 'env set to true' do
      it 'returns true' do
        env = {:provision_enabled => true}
        expect(provision_enabled?(env)).to be_truthy
      end
    end
    context 'env set to false' do
      it 'returns false' do
        env = {:provision_enabled => false}
        expect(provision_enabled?(env)).to be_falsey
      end
    end
  end

  describe '#env_dir' do
    it 'returns root_path' do
      env = {:root_path => '/foo'}
      expect(env_dir(env)).to eq('/foo')
    end
  end

  describe '#puppetfile_path' do
    before { allow_any_instance_of(VagrantPlugins::R10k::Helpers).to receive(:env_dir).and_return('/my/env/dir') }
    it 'returns joined path' do
      env = {:machine => double}
      env[:machine].stub_chain(:config, :r10k, :puppetfile_path).and_return('path/to/puppetfile')
      expect(puppetfile_path(env)).to eq('/my/env/dir/path/to/puppetfile')
    end
  end

  describe '#puppet_provisioner' do
    context 'one puppet provisioner with :type' do
      it 'returns that provisioner' do
        # double for puppet provisioner
        prov_dbl = double
        allow(prov_dbl).to receive(:type).and_return(:puppet)
        provisioners = [prov_dbl]
        # double for env
        env = {:machine => double}
        env[:machine].stub_chain(:config, :vm, :provisioners).and_return(provisioners)
        expect(puppet_provisioner(env)).to eq(prov_dbl)
      end
    end
    context 'one puppet provisioner with :name' do
      it 'returns that provisioner' do
        # double for puppet provisioner
        prov_dbl = double
        allow(prov_dbl).to receive(:name).and_return(:puppet)
        provisioners = [prov_dbl]
        # double for env
        env = {:machine => double}
        env[:machine].stub_chain(:config, :vm, :provisioners).and_return(provisioners)
        expect(puppet_provisioner(env)).to eq(prov_dbl)
      end
    end
    context 'no puppet provisioners' do
      it 'returns nil' do
        # double for chef provisioner
        prov_dbl = double
        allow(prov_dbl).to receive(:name).and_return(:chef)
        # double for 'soemthing' provisioner
        prov2_dbl = double
        allow(prov2_dbl).to receive(:name).and_return(:something)
        provisioners = [prov_dbl, prov2_dbl]
        # double for env
        env = {:machine => double}
        env[:machine].stub_chain(:config, :vm, :provisioners).and_return(provisioners)
        expect(puppet_provisioner(env)).to be_nil
      end
    end
    context 'two puppet provisioners' do
      it 'returns last provisioner' do
        # double for puppet provisioner
        prov_dbl = double
        allow(prov_dbl).to receive(:type).and_return(:puppet)
        # double for other puppet provisioner
        prov2_dbl = double
        allow(prov2_dbl).to receive(:name).and_return(:puppet)
        provisioners = [prov_dbl, prov2_dbl]
        # double for env
        env = {:machine => double}
        env[:machine].stub_chain(:config, :vm, :provisioners).and_return(provisioners)
        expect(puppet_provisioner(env)).to eq(prov2_dbl)
      end
    end
  end

  describe '#r10k_config' do
    context 'puppet_provisioner is nil' do
      before do
        allow_any_instance_of(VagrantPlugins::R10k::Helpers).to receive(:env_dir).and_return('/my/env/dir')
        allow_any_instance_of(VagrantPlugins::R10k::Helpers).to receive(:puppetfile_path).and_return('puppet/file/path')
        allow_any_instance_of(VagrantPlugins::R10k::Helpers).to receive(:puppet_provisioner).and_return(nil)
      end
      it 'returns nil' do
        env = double
        expect(r10k_config(env)).to be_nil
      end
    end
    context 'module_path is nil' do
      before do
        allow_any_instance_of(VagrantPlugins::R10k::Helpers).to receive(:env_dir).and_return('/my/env/dir')
        allow_any_instance_of(VagrantPlugins::R10k::Helpers).to receive(:puppetfile_path).and_return('puppet/file/path')
        allow_any_instance_of(VagrantPlugins::R10k::Helpers).to receive(:puppet_provisioner).and_return(:pup_prov)
        allow_any_instance_of(VagrantPlugins::R10k::Helpers).to receive(:module_path).and_return(nil)
      end
      it 'returns nil' do
        env = double
        expect(r10k_config(env)).to be_nil
      end
    end
    context 'no methods return nil' do
      before do
        prov_dbl = double
        prov_dbl.stub_chain(:config, :manifest_file).and_return('manifest/file')
        prov_dbl.stub_chain(:config, :manifests_path).and_return([0, 'manifests/path'])
        allow_any_instance_of(VagrantPlugins::R10k::Helpers).to receive(:env_dir).and_return('/my/env/dir')
        allow_any_instance_of(VagrantPlugins::R10k::Helpers).to receive(:puppetfile_path).and_return('puppet/file/path')
        allow_any_instance_of(VagrantPlugins::R10k::Helpers).to receive(:puppet_provisioner).and_return(prov_dbl)
        allow_any_instance_of(VagrantPlugins::R10k::Helpers).to receive(:module_path).and_return('module/path')
      end
      it 'returns config' do
        env = {:machine => double}
        env[:machine].stub_chain(:config, :r10k, :puppet_dir).and_return('puppet/dir')
        expect(r10k_config(env)).to eq({
                                         :env_dir_path    => '/my/env/dir',
                                         :puppetfile_path => 'puppet/file/path',
                                         :module_path     => 'module/path',
                                         :manifest_file   => '/my/env/dir/manifest/file',
                                         :manifests       => '/my/env/dir/manifests/path',
                                         :puppet_dir      => '/my/env/dir/puppet/dir',
                                       })
      end
    end
  end

  describe '#module_path' do
    context 'config.r10k.module_path unset and provisioner module_path nil' do
      it 'returns nil' do
        prov_dbl = double
        prov_dbl.stub_chain(:config, :module_path).and_return(nil)
        env = {:machine => double, :ui => double}
        allow(env[:ui]).to receive(:info).with("vagrant-r10k: Building the r10k module path with puppet provisioner module_path \"\". (if module_path is an array, first element is used)")
        env[:machine].stub_chain(:config, :r10k, :module_path).and_return(Vagrant::Plugin::V2::Config::UNSET_VALUE)
        expect(module_path(env, prov_dbl, '/env/dir/path')).to be_nil
      end
    end
    context 'config.r10k.module_path unset and provisioner module_path string' do
      it 'returns the joined module_path' do
        prov_dbl = double
        prov_dbl.stub_chain(:config, :module_path).and_return('module/path')
        env = {:machine => double, :ui => double}
        allow(env[:ui]).to receive(:info).with("vagrant-r10k: Building the r10k module path with puppet provisioner module_path \"module/path\". (if module_path is an array, first element is used)")
        env[:machine].stub_chain(:config, :r10k, :module_path).and_return('module/path')
        expect(module_path(env, prov_dbl, '/env/dir/path')).to eq('/env/dir/path/module/path')
      end
    end
    context 'config.r10k.module_path unset and provisioner module_path array' do
      it 'returns the joined first module_path' do
        prov_dbl = double
        prov_dbl.stub_chain(:config, :module_path).and_return(['module/path', 'foo'])
        env = {:machine => double, :ui => double}
        allow(env[:ui]).to receive(:info).with("vagrant-r10k: Building the r10k module path with puppet provisioner module_path \"module/path\". (if module_path is an array, first element is used)")
        env[:machine].stub_chain(:config, :r10k, :module_path).and_return('module/path')
        expect(module_path(env, prov_dbl, '/env/dir/path')).to eq('/env/dir/path/module/path')
      end
    end
    context 'provisioner module_path array doesnt include r10k module_path' do
      it 'raises ErrorWrapper' do
        prov_dbl = double
        prov_dbl.stub_chain(:config, :module_path).and_return(['module/path', 'foo'])
        env = {:machine => double, :ui => double}
        allow(env[:ui]).to receive(:info).with("vagrant-r10k: Building the r10k module path with puppet provisioner module_path \"\". (if module_path is an array, first element is used)")
        env[:machine].stub_chain(:config, :r10k, :module_path).and_return('r10kmodule/path')
        expect { module_path(env, prov_dbl, '/env/dir/path') }.to raise_error(VagrantPlugins::R10k::Helpers::ErrorWrapper, /module_path "r10kmodule\/path" is not within the ones defined in puppet provisioner; please correct this condition/)
      end
    end
    context 'provisioner module_path string doesnt match r10k module_path' do
      it 'raises ErrorWrapper' do
        prov_dbl = double
        prov_dbl.stub_chain(:config, :module_path).and_return('module/path')
        env = {:machine => double, :ui => double}
        allow(env[:ui]).to receive(:info).with("vagrant-r10k: Building the r10k module path with puppet provisioner module_path \"\". (if module_path is an array, first element is used)")
        env[:machine].stub_chain(:config, :r10k, :module_path).and_return('r10kmodule/path')
        expect { module_path(env, prov_dbl, '/env/dir/path') }.to raise_error(VagrantPlugins::R10k::Helpers::ErrorWrapper, /module_path "r10kmodule\/path" is not the same as in puppet provisioner \(module\/path\); please correct this condition/)
      end
    end
    context 'config.r10k.module_path set and provisioner module_path nil' do
      it 'returns the joined module_path' do
        prov_dbl = double
        prov_dbl.stub_chain(:config, :module_path).and_return(nil)
        env = {:machine => double, :ui => double}
        allow(env[:ui]).to receive(:info).with("vagrant-r10k: Puppet provisioner module_path is nil, assuming puppet4 environment mode")
        env[:machine].stub_chain(:config, :r10k, :module_path).and_return('module/path')
        expect(module_path(env, prov_dbl, '/env/dir/path')).to eq('/env/dir/path/module/path')
      end
    end
  end

  describe '#get_puppetfile' do
    it 'returns a Puppetfile' do
      config = {
        :puppet_dir      => 'puppet/dir',
        :module_path     => 'module/path',
        :puppetfile_path => 'puppetfile/path',
      }
      res = get_puppetfile(config)
      expect(res).to be_a_kind_of(R10K::Puppetfile)
      expect(res.instance_variable_get(:@basedir)).to eq('puppet/dir')
      expect(res.instance_variable_get(:@moduledir)).to eq('module/path')
      expect(res.instance_variable_get(:@puppetfile_path)).to eq('puppetfile/path')
    end
  end

end
