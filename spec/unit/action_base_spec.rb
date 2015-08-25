require 'spec_helper'
require_relative 'sharedcontext'
require_relative 'shared_expectations'
require 'vagrant-r10k/action/base'

include SharedExpectations

describe VagrantPlugins::R10k::Action::Base do
  include_context 'vagrant-unit'
  context 'instantiation' do

    it 'has app and env instance variables' do
      x = described_class.new(:app, :env)
      expect(x.instance_variable_get(:@app)).to equal(:app)
      expect(x.instance_variable_get(:@env)).to equal(:env)
    end

    it 'has a logger' do
      x = described_class.new(:app, :env)
      expect(x.instance_variable_get(:@logger)).to be_a_kind_of(Log4r::Logger)
      expect(x.instance_variable_get(:@logger).fullname).to eq('vagrant::r10k::base')
    end

    it 'sets logging levels to 3 when not running in debug mode' do
      allow(ENV).to receive(:[]).with("VAGRANT_LOG").and_return('no')
      x = described_class.new(:app, :env)
      expect(R10K::Logging.level).to eq(3)
    end

    it 'sets logging levels to 0 when running in debug mode' do
      allow(ENV).to receive(:[]).with("VAGRANT_LOG").and_return('debug')
      x = described_class.new(:app, :env)
      expect(R10K::Logging.level).to eq(0)
      expect(x.instance_variable_get(:@logger).level).to eq(0)
    end
  end

  context 'validate' do
    it 'returns Vagrant::Action::Builder with Action::Validate' do
      res = described_class.validate
      expect(res).to be_a_kind_of(Vagrant::Action::Builder)
      expect(res.stack).to eq([[VagrantPlugins::R10k::Action::Validate, [], nil]])
    end
  end

  context 'deploy' do
    it 'returns Vagrant::Action::Builder with Action::Validate and Action::Deploy' do
      res = described_class.deploy
      expect(res).to be_a_kind_of(Vagrant::Action::Builder)
      expect(res.stack).to eq([
                                [VagrantPlugins::R10k::Action::Validate, [], nil],
                                [VagrantPlugins::R10k::Action::Deploy, [], nil]
                              ])
    end

  end
end
