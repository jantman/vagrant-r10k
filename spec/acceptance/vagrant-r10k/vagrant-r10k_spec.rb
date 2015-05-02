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

    it 'deploys the modules' do
      result = assert_execute('vagrant', 'up', "--provider=#{provider}")
      expect(result).to exit_with(0)
      puts result.stdout
      expect(result.stdout).to include('r10k')
      expect(result.stderr).to match(//)
      # reviewboard module deploy
      rb_dir = File.join(environment.workdir, 'puppet', 'modules', 'reviewboard')
      expect(File.directory?(rb_dir)).to be_truthy
      # nodemeister module deploy
      nm_dir = File.join(environment.workdir, 'puppet', 'modules', 'nodemeister')
      expect(File.directory?(nm_dir)).to be_truthy
      # result = assert_execute('gitcheck.sh', 'puppet/modules/reviewboard')
      # reviewboard v1.0.1 -> cdb8d7a186846b49326cec1cfb4623bd77529b04 git@github.com:jantman/puppet-reviewboard.git
      # nodemeister 0.1.0 -> 3a504b5f66ebe1853bda4ee065fce18118958d84 git@github.com:jantman/puppet-nodemeister.git
    end
  end
end
