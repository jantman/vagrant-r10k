require 'spec_helper'

require 'vagrant-r10k/helpers'

describe R10K::TaskRunner do
  subject { described_class.new }
  describe '#get_errors' do
    it 'returns @errors' do
      subject.instance_variable_set(:@errors, ['foo'])
      expect(subject).to receive(:get_errors).once.and_call_original
      foo = subject.get_errors
      expect(foo).to eq(['foo'])
    end
  end
end
