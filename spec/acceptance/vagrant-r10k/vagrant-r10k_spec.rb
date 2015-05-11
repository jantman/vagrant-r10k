shared_examples 'provider/vagrant-r10k' do |provider, options|
  # NOTE: vagrant-spec's acceptance framework (specifically IsolatedEnvironment)
  # creates an isolated environment for each 'it' block and tears it down afterwards.
  # This *only* works with the layout below. As such, quite unfortunately, we have a
  # bunch of assertions in each 'it' block; they're not isolated the way they should be.
  # The alternative is to run a complete up/provision/assert/destroy cycle for each
  # assertion we want to make, and also therefore lose the ability to make multiple
  # assertions about one provisioning run.

  if !File.file?(options[:box])
    raise ArgumentError,
      "A box file #{options[:box]} must be downloaded for provider: #{provider}. The rake task should have done this."
  end

  include_context 'acceptance'

  let(:box_ip) { '10.10.10.29' }
  let(:name)   { 'single.testbox.spec' }

  before do
    ENV['VAGRANT_DEFAULT_PROVIDER'] = provider
  end

  describe 'configured correctly' do
    before do
      environment.skeleton('correct')
      assert_execute('vagrant', 'box', 'add', "vagrantr10kspec", options[:box])
    end
    after do
      assert_execute("vagrant", "destroy", "--force")
      assert_execute('vagrant', 'box', 'remove', 'vagrantr10kspec', '-f')
    end

    it 'deploys Puppetfile modules' do
      status("ls")
      ls_home = assert_execute('find', "#{environment.homedir}", '-ls')
      puts "##### homedir (#{environment.homedir}):"
      puts ls_home.stdout
      ls_work = assert_execute('find', "#{environment.workdir}", '-ls')
      puts "##### workdir (#{environment.workdir}):"
      puts ls_work.stdout
      df_tmp = assert_execute('df', '-h', '/tmp')
      puts "#### df -h /tmp -> #{df_tmp.stdout}"
      status("Test: vagrant up")
      up_result = assert_execute('vagrant', 'up', "--provider=#{provider}")
      expect(up_result).to exit_with(0)
      expect(up_result.stdout).to include('vagrant-r10k: Building the r10k module path with puppet provisioner module_path "puppet/modules"')
      expect(up_result.stdout).to include("vagrant-r10k: Beginning r10k deploy of puppet modules into #{environment.workdir}/puppet/modules using #{environment.workdir}/puppet/Puppetfile")
      expect(up_result.stdout).to include('vagrant-r10k: Deploy finished')
      expect(up_result.stdout).to include('Running Puppet with default.pp')
      expect(up_result.stdout).to include('vagrant-r10k puppet run')
      expect(up_result.stderr).to match(/^$/)
      puts up_result.stdout

      status("Test: reviewboard module")
      rb_dir = File.join(environment.workdir, 'puppet', 'modules', 'reviewboard')
      expect(File.directory?(rb_dir)).to be_truthy
      rb_result = assert_execute('bash', 'gitcheck.sh', 'puppet/modules/reviewboard')
      expect(rb_result).to exit_with(0)
      expect(rb_result.stdout).to match(/tag: v1\.0\.1 @ cdb8d7a186846b49326cec1cfb4623bd77529b04 \(origin: https:\/\/github\.com\/jantman\/puppet-reviewboard\.git\)/)
      
      status("Test: nodemeister module")
      nm_dir = File.join(environment.workdir, 'puppet', 'modules', 'nodemeister')
      expect(File.directory?(nm_dir)).to be_truthy
      nm_result = assert_execute('bash', 'gitcheck.sh', 'puppet/modules/nodemeister')
      expect(nm_result).to exit_with(0)
      expect(nm_result.stdout).to match(/tag: 0\.1\.0 @ 3a504b5f66ebe1853bda4ee065fce18118958d84 \(origin: https:\/\/github\.com\/jantman\/puppet-nodemeister\.git\)/)
    end
  end

  describe 'puppet directory missing' do
    # this is a complete failure
    before do
      environment.skeleton('no_puppet_dir')
      assert_execute('vagrant', 'box', 'add', "vagrantr10kspec", options[:box])
    end
    after do
      assert_execute("vagrant", "destroy", "--force")
      assert_execute('vagrant', 'box', 'remove', 'vagrantr10kspec', '-f')
    end

    it 'errors during config validation' do
      status("Test: vagrant up")
      up_result = execute('vagrant', 'up', "--provider=#{provider}")
      expect(up_result).to exit_with(1)
      expect(up_result.stderr).to match(/RuntimeError: Puppetfile at .* does not exist/)
      expect(up_result.stdout).to include('vagrant-r10k: Building the r10k module path with puppet provisioner module_path "puppet/modules"')
      # TODO expect(up_result.stdout).to_not include("vagrant-r10k: Beginning r10k deploy of puppet modules")
      expect(up_result.stdout).to_not include('Running Puppet with default.pp')
      expect(up_result.stdout).to_not include('vagrant-r10k puppet run')
      expect(up_result.stdout).to_not include('vagrant-r10k: Deploy finished')
    end
  end

  describe 'module path different from Puppet provisioner' do
    # this just doesn't run the r10k portion
    before do
      environment.skeleton('different_mod_path')
      assert_execute('vagrant', 'box', 'add', "vagrantr10kspec", options[:box])
      puts "#### executed box add; homedir=#{environment.homedir} workdir=#{environment.workdir}"
    end
    after do
      assert_execute("vagrant", "destroy", "--force")
      assert_execute('vagrant', 'box', 'remove', 'vagrantr10kspec', '-f')
    end

    it 'skips r10k deploy' do
      status("ls")
      ls_home = assert_execute('find', "#{environment.homedir}", '-ls')
      puts "##### homedir (#{environment.homedir}):"
      puts ls_home.stdout
      ls_work = assert_execute('find', "#{environment.workdir}", '-ls')
      puts "##### workdir (#{environment.workdir}):"
      puts ls_work.stdout
      df_tmp = assert_execute('df', '-h', '/tmp')
      puts "#### df -h /tmp -> #{df_tmp.stdout}"
      status("Test: vagrant up")
      up_result = execute('vagrant', 'up', "--provider=#{provider}")
      expect(up_result).to exit_with(0)
      expect(up_result.stderr).to match(/^$/)
      expect(up_result.stdout).to include('vagrant-r10k: module_path "puppet/NOTmodules" is not the same as in puppet provisioner; not running')
      expect(up_result.stdout).to_not include("vagrant-r10k: Beginning r10k deploy of puppet modules")
      expect(up_result.stdout).to_not include('vagrant-r10k: Building the r10k module path with puppet provisioner module_path')
      expect(up_result.stdout).to_not include('vagrant-r10k: Deploy finished')
      expect(up_result.stdout).to include('Running Puppet with default.pp')
      expect(up_result.stdout).to include('vagrant-r10k puppet run')
    end
  end

  describe 'Puppetfile syntax error' do
    # r10k runtime failure
    before do
      environment.skeleton('puppetfile_syntax_error')
      assert_execute('vagrant', 'box', 'add', "vagrantr10kspec", options[:box])
    end
    after do
      assert_execute("vagrant", "destroy", "--force")
      assert_execute('vagrant', 'box', 'remove', 'vagrantr10kspec', '-f')
    end

    it 'fails during module deploy' do
      status("Test: vagrant up")
      up_result = execute('vagrant', 'up', "--provider=#{provider}")
      expect(up_result).to exit_with(1)
      expect(up_result.stdout).to include("vagrant-r10k: Beginning r10k deploy of puppet modules")
      expect(up_result.stdout).to include('vagrant-r10k: Building the r10k module path with puppet provisioner module_path')
      expect(up_result.stdout).to_not include('vagrant-r10k: Deploy finished')
      expect(up_result.stdout).to_not include('Running provisioner')
      expect(up_result.stdout).to_not include('Running Puppet with default.pp')
      expect(up_result.stdout).to_not include('vagrant-r10k puppet run')
      expect(up_result.stderr).to include("Invalid syntax in Puppetfile at")
    end
  end
end
