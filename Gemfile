source 'https://rubygems.org'

group :development do
  if ENV.has_key?('VAGRANT_VERSION')
    gem "vagrant", git: "https://github.com/mitchellh/vagrant.git", tag: "v#{ENV['VAGRANT_VERSION']}"
  else
    gem "vagrant", git: "https://github.com/mitchellh/vagrant.git", branch: 'master'
  end
  # Pinned on 12/10/2014. Compatible with Vagrant 1.5.x, 1.6.x and 1.7.x.
  gem 'vagrant-spec', :github => 'mitchellh/vagrant-spec', :ref => '1df5a3a'
  gem 'simplecov', :require => false
  gem 'codecov', :require => false
  gem "rspec_junit_formatter", :require => false
end

group :plugins do
  gemspec
end
