source 'https://rubygems.org'

group :development do
  if ENV.has_key?('VAGRANT_VERSION')
    gem "vagrant", git: "https://github.com/mitchellh/vagrant.git", tag: "v#{ENV['VAGRANT_VERSION']}"
  else
    gem "vagrant", git: "https://github.com/mitchellh/vagrant.git", branch: 'master'
  end
  # pinned to branch for https://github.com/mitchellh/vagrant-spec/pull/16
  gem 'vagrant-spec', :github => 'jantman/vagrant-spec', :ref => 'junit_and_env'
  gem 'simplecov', :require => false
  gem 'codecov', :require => false
  gem "rspec_junit_formatter", :require => false
  gem 'rspec-matcher-num-times', git: "https://github.com/jantman/rspec-matcher-num-times.git", branch: 'rspec2'
end

group :plugins do
  gemspec
end
