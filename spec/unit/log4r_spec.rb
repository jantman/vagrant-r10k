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
