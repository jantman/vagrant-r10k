require 'spec_helper'
require_relative 'sharedcontext'
require_relative 'shared_expectations'
require 'vagrant-r10k/plugin'

include SharedExpectations

describe VagrantPlugins::R10k::Plugin do
  include_context 'vagrant-unit'
  context 'unsupported vagrant version' do
    it 'should abort on Vagrant < 1.2' do
      stub_const("Vagrant::VERSION", "1.1.0")
      expect { load 'vagrant-r10k/plugin.rb', wrap=true }.to raise_error(RuntimeError, "The Vagrant r10k plugin is only compatible with Vagrant 1.2+")
    end
  end
  context 'action hooks' do
    let(:hook) { double(append: true, prepend: true) }
    it 'should set hooks' do
      # I had lots of problems with this, but found an example at:
      # https://github.com/petems/vagrant-puppet-install/blob/60b26f8d4f4d82b687bc527b239cba2baaf95731/test/unit/vagrant-puppet-install/plugin_spec.rb
      hook_proc = described_class.components.action_hooks[:__all_actions__][0]
      hook = double
      expect(hook).to receive(:before).with(Vagrant::Action::Builtin::Provision, VagrantPlugins::R10k::Modulegetter)
      expect(hook).to receive(:before).with(Vagrant::Action::Builtin::ConfigValidate, VagrantPlugins::R10k::Modulegetter)
      hook_proc.call(hook)
    end
  end
  context 'config' do
    it 'registers itself' do
      expect(described_class.components.configs[:top].key?(:r10k)).to be_truthy
    end
    it 'uses the Config class' do
      cfg = described_class.components.configs[:top].get(:r10k)
      expect(cfg).to eq(VagrantPlugins::R10k::Config)
    end
  end
  context 'attributes' do
    it 'should have the proper name' do
      expect(described_class.name).to eq('vagrant-r10k')
    end
    it 'should have the proper description' do
      expect(described_class.description).to eq('Retrieve puppet modules based on a Puppetfile')
    end
  end
  context 'instantiation' do
    it 'is a vagrant v2 plugin' do
      x = described_class.new
      expect(x).to be_a_kind_of(Vagrant::Plugin::V2::Plugin)
    end
  end
end
