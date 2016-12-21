module SharedExpectations
  def expect_ran_successfully(vars)
    # expect it to run with the right arguments, etc.
    mp = vars[:module_path]
    full_puppetfile_path = File.join(vars[:rootpath], vars[:puppetfile_path])
    full_puppet_dir = File.join(vars[:rootpath], vars[:puppet_dir])
    full_module_path = File.join(vars[:rootpath], vars[:module_path])
    expect(vars[:ui]).to receive(:info).with("vagrant-r10k: Building the r10k module path with puppet provisioner module_path \"#{mp}\". (if module_path is an array, first element is used)").once
    File.stub(:file?).with(full_puppetfile_path).and_return(true)
    expect(vars[:ui]).to receive(:info).with(/Beginning r10k deploy/).once
    R10K::Puppetfile.stub(:new)
    expect(R10K::Puppetfile).to receive(:new).with(full_puppet_dir, full_module_path, full_puppetfile_path).once
    R10K::Action::Puppetfile::Sync.stub(:new).and_call_original
    expect(R10K::Action::Puppetfile::Sync).to receive(:new).once
    runner = R10K::TaskRunner.new([])
    R10K::TaskRunner.stub(:new).and_return(runner)
    R10K::TaskRunner.stub(:append_task).and_call_original
    runner.stub(:run)
    runner.stub(:succeeded?).and_return(true)
    runner.stub(:get_errors).and_return([])
    expect(runner).to receive(:append_task).once
    expect(runner).to receive(:run).once
    expect(vars[:ui]).to receive(:info).with('vagrant-r10k: Deploy finished').once
    expect(ui).to receive(:error).exactly(0).times
  end

  def expect_did_not_run(ui, app, env, nobegin=true, appcall=true)
    # expect it to not really run
    if appcall
      expect(app).to receive(:call).with(env).once
    end
    if nobegin
      expect(ui).to receive(:info).with(/Beginning r10k deploy/).exactly(0).times
    end
    R10K::Puppetfile.stub(:new)
    expect(R10K::Puppetfile).to receive(:new).exactly(0).times
    runner = R10K::TaskRunner.new([])
    R10K::TaskRunner.stub(:new).and_return(runner)
    R10K::TaskRunner.stub(:append_task).and_call_original
    runner.stub(:run)
    runner.stub(:succeeded?).and_return(false)
    runner.stub(:get_errors).and_return(['foo'])
    expect(runner).to receive(:append_task).exactly(0).times
    expect(runner).to receive(:run).exactly(0).times
  end
end


