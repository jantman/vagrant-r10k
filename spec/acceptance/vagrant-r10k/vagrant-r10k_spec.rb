shared_examples 'provider/vagrant-r10k' do |provider, options|

  if !File.file?(options[:box])
    raise ArgumentError,
      "A box file #{options[:box]} must be downloaded for provider: #{provider}. The rake task should have done this."
  end

  include_context 'acceptance'

  let(:box_ip) { '10.10.10.29' }
  let(:name)   { 'single.testbox.spec' }

  before do
    assert_execute('vagrant', 'box', 'add', "vagrantr10kspec", options[:box])
    ENV['VAGRANT_DEFAULT_PROVIDER'] = provider
  end

  describe 'configured correctly' do
    before do
      environment.skeleton('correct')
      puts "Isolated Environment: homedir=#{environment.homedir} workdir=#{environment.workdir}"
    end

    after do
      assert_execute("vagrant", "destroy", "--force")
    end

    it 'deploys once' do
      #result = assert_execute('vagrant', 'up', "--provider=#{provider}", "--debug")
      result = assert_execute('vagrant', 'up', "--provider=#{provider}")
      expect(result).to exit_with(0)
      expect(result.stdout).to include('r10k')
      expect(result.stderr).to match(//)
    end
  end
end
