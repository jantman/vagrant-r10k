require 'spec_helper'
require_relative 'sharedcontext'
require_relative 'shared_expectations'
require 'vagrant-r10k/plugin'
require 'vagrant-r10k/action/base'

include SharedExpectations

describe VagrantPlugins::R10k::Plugin do
  include_context 'vagrant-unit'
  context 'action hooks' do
    let(:hook) { double(append: true, prepend: true) }
    it 'should set hooks' do
      # I had lots of problems with this, but found an example at:
      # https://github.com/petems/vagrant-puppet-install/blob/60b26f8d4f4d82b687bc527b239cba2baaf95731/test/unit/vagrant-puppet-install/plugin_spec.rb
      [:machine_action_up, :machine_action_reload, :machine_action_provision].each do |action|
        hook_proc = described_class.components.action_hooks[action][0]
        hook = double
        VagrantPlugins::R10k::Action::Base.stub(:validate => 'foo', :deploy => 'bar')
        expect(hook).to receive(:after).with(Vagrant::Action::Builtin::ConfigValidate, 'foo')
        expect(hook).to receive(:before).with(Vagrant::Action::Builtin::Provision, 'bar')
        hook_proc.call(hook)
      end
    end
  end
  context 'config' do
    it 'registers itself' do
      expect(described_class.components.configs[:top].get(:r10k)).to_not be_nil
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
