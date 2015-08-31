include VagrantPlugins::R10k
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
      setup_before('correct', options)
    end
    after do
      assert_execute("vagrant", "destroy", "--force")
    end

    it 'deploys Puppetfile modules' do
      status("Test: vagrant up")
      up_result = assert_execute('vagrant', 'up', "--provider=#{provider}", '--debug')
      ensure_successful_run(up_result, environment.workdir)
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

  describe 'destroy when configured correctly' do
    before do
      setup_before('correct', options)
    end
    after do
      assert_execute("vagrant", "destroy", "--force")
    end

    it 'does not deploy modules' do
      status("Test: vagrant up destroy")
      assert_execute('vagrant', 'up', "--provider=#{provider}", '--debug')
      destroy_result = assert_execute("vagrant", "destroy", "--force", '--debug')
      expect(destroy_result.stdout).to_not include("vagrant-r10k: Beginning r10k deploy of puppet modules")
      expect(destroy_result.stdout).to_not include('vagrant-r10k: Building the r10k module path')
      expect(destroy_result.stdout).to_not include('vagrant-r10k: Deploy finished')
      expect(destroy_result.stderr).to_not include("vagrant-r10k: Beginning r10k deploy of puppet modules")
      expect(destroy_result.stderr).to_not include('vagrant-r10k: Building the r10k module path')
      expect(destroy_result.stderr).to_not include('vagrant-r10k: Deploy finished')
    end
  end

  describe 'puppet directory missing' do
    # this is a complete failure
    before do
      setup_before('no_puppet_dir', options)
    end
    after do
      assert_execute("vagrant", "destroy", "--force")
    end

    it 'errors during config validation' do
      status("Test: vagrant up")
      up_result = execute('vagrant', 'up', "--provider=#{provider}", '--debug')
      ensure_r10k_didnt_run(up_result, environment.workdir)
      expect(up_result).to exit_with(1)
      expect(up_result.stderr).to match(/puppetfile '[^']+' does not exist/)
      ensure_puppet_didnt_run(up_result)
    end
  end

  describe 'module path different from Puppet provisioner' do
    # this just doesn't run the r10k portion
    before do
      setup_before('different_mod_path', options)
    end
    after do
      assert_execute("vagrant", "destroy", "--force")
    end

    it 'throws RuntimeError' do
      status("Test: vagrant up")
      up_result = execute('vagrant', 'up', "--provider=#{provider}")
      expect(up_result).to exit_with(1)
      expect(up_result.stderr).to match('RuntimeError: vagrant-r10k: module_path "puppet/NOTmodules" is not the same as in puppet provisioner; please correct this condition')
      ensure_r10k_didnt_run(up_result, environment.workdir)
      ensure_puppet_didnt_run(up_result)
    end
  end

  describe 'no module path set' do
    # this just doesn't run the r10k portion
    before do
      setup_before('no_mod_path', options)
    end
    after do
      assert_execute("vagrant", "destroy", "--force")
    end

    it 'skips r10k deploy' do
      status("Test: vagrant up")
      up_result = execute('vagrant', 'up', "--provider=#{provider}", '--debug')
      expect(up_result).to exit_with(1)
      ensure_r10k_didnt_run(up_result, environment.workdir)
      ensure_puppet_didnt_run(up_result)
    end
  end

  describe 'no r10k configuration' do
    # this just doesn't run the r10k portion
    before do
      setup_before('no_vagrant_r10k', options)
    end
    after do
      assert_execute("vagrant", "destroy", "--force")
    end

    it 'skips r10k deploy' do
      status("Test: vagrant up")
      up_result = execute('vagrant', 'up', "--provider=#{provider}")
      expect(up_result).to exit_with(0)
      expect(up_result.stdout).to include("vagrant-r10k not configured; skipping")
      ensure_r10k_didnt_run(up_result, environment.workdir)
      ensure_puppet_ran(up_result)
    end
  end

  describe 'Puppetfile syntax error' do
    # r10k runtime failure
    before do
      setup_before('puppetfile_syntax_error', options)
    end
    after do
      assert_execute("vagrant", "destroy", "--force")
    end

    it 'fails during module deploy' do
      status("Test: vagrant up")
      up_result = execute('vagrant', 'up', "--provider=#{provider}")
      expect(up_result).to exit_with(1)
      expect(up_result.stderr).to match(%r"SyntaxError: .*puppet/Puppetfile:1: syntax error, unexpected tIDENTIFIER, expecting '\('\s+this is not a valid puppetfile\s+\^")
      ensure_r10k_didnt_run(up_result, environment.workdir)
      ensure_puppet_didnt_run(up_result)
    end
  end

  # setup skeleton, add box
  def setup_before(skel_name, options)
    environment.skeleton(skel_name)
    environment.env['VBOX_USER_HOME'] = environment.homedir.to_s
    assert_execute('vagrant', 'box', 'add', "vagrantr10kspec", options[:box])
  end

  # checks for a successful up run with r10k deployment and puppet provisioning
  def ensure_successful_run(up_result, workdir)
    expect(up_result).to exit_with(0)
    # version checks
    expect(up_result.stderr).to include('global:   - r10k = 1.2.1')
    expect(up_result.stderr).to include("global:   - vagrant-r10k = #{VagrantPlugins::R10k::VERSION}")
    expect(up_result.stderr).to include('Registered plugin: vagrant-r10k')
    expect(up_result.stderr).to include('vagrant::r10k::validate called')
    expect(up_result.stderr).to include('vagrant::r10k::deploy called')
    expect(up_result.stderr).to match_num_times(1, %r"DEBUG config: vagrant-r10k-config: validate.*DEBUG validate: vagrant::r10k::validate called.*Running action: provisioner_run"m), "config and validate run before provisioner"
    expect(up_result.stderr).to match_num_times(1, %r"DEBUG deploy: vagrant::r10k::deploy called.*Running action: provisioner_run"m), "deploy runs before provisioners"
    # provisioning runs
    expect(up_result.stdout).to include_num_times(1, '==> default: vagrant-r10k: Beginning r10k deploy of puppet modules into'), "provisioning runs once"
    # modulegetter runs before provisioning
    expect(up_result.stdout).to match_num_times(1, %r"vagrant-r10k: Deploy finished.*\s+Running provisioner: puppet"m), "deploy runs before puppet provisioner"
    # modulegetter BEFORE ConfigValidate
    expect(up_result.stderr).to match(%r"(?!ConfigValidate)+default: vagrant-r10k: Deploy finished.*Vagrant::Action::Builtin::ConfigValidate"m), "modulegetter runs before ConfigValidate"
    # other checks
    expect(up_result.stdout).to include('vagrant-r10k: Building the r10k module path with puppet provisioner module_path "puppet/modules"')
    expect(up_result.stdout).to include("vagrant-r10k: Beginning r10k deploy of puppet modules into #{workdir}/puppet/modules using #{workdir}/puppet/Puppetfile")
    expect(up_result.stdout).to include('vagrant-r10k: Deploy finished')
    # file tests
    expect(File).to exist("#{workdir}/puppet/modules/reviewboard/Modulefile")
    expect(File).to exist("#{workdir}/puppet/modules/nodemeister/Modulefile")
    expect(File).to exist("#{workdir}/puppet/modules/nodemeister/manifests/init.pp")

    # ensure puppet ran
    ensure_puppet_ran(up_result)
  end

  # ensure that r10k didnt run
  def ensure_r10k_didnt_run(up_result, workdir)
    expect(up_result.stdout).to_not include("vagrant-r10k: Beginning r10k deploy of puppet modules")
    expect(up_result.stdout).to_not include('vagrant-r10k: Deploy finished')

    # file tests
    expect(File).to_not exist("#{workdir}/puppet/modules/reviewboard/Modulefile")
    expect(File).to_not exist("#{workdir}/puppet/modules/nodemeister/Modulefile")
    expect(File).to_not exist("#{workdir}/puppet/modules/nodemeister/manifests/init.pp")
  end

  # ensure that the puppet provisioner ran with default.pp
  def ensure_puppet_ran(up_result)
    expect(up_result.stdout).to include('Running provisioner: puppet')
    expect(up_result.stdout).to include('Running Puppet with default.pp')
    expect(up_result.stdout).to include('vagrant-r10k puppet run')
  end

  # ensure that the puppet provisioner DIDNT run
  def ensure_puppet_didnt_run(up_result)
    expect(up_result.stdout).to_not include('Running provisioner: puppet')
    expect(up_result.stdout).to_not include('Running Puppet with default.pp')
    expect(up_result.stdout).to_not include('vagrant-r10k puppet run')
  end

  # method to print output
  def print_output(up_result)
    puts "################# STDOUT #####################"
    puts up_result.stdout
    puts "################# STDERR #####################"
    puts up_result.stderr
    puts "################# END #####################"
  end
end
