# Vagrant::R10k

[![Build Status](https://travis-ci.org/jantman/vagrant-r10k.svg?branch=master)](https://travis-ci.org/jantman/vagrant-r10k)
[![Code Coverage](https://codecov.io/github/jantman/vagrant-r10k/coverage.svg?branch=master)](https://codecov.io/github/jantman/vagrant-r10k?branch=master)
[![Code Climate](https://codeclimate.com/github/jantman/vagrant-r10k/badges/gpa.svg)](https://codeclimate.com/github/jantman/vagrant-r10k)
[![Gem Version](https://img.shields.io/gem/v/vagrant-r10k.svg)](https://rubygems.org/gems/vagrant-r10k)
[![Total Downloads](https://img.shields.io/gem/dt/vagrant-r10k.svg)](https://rubygems.org/gems/vagrant-r10k)
[![Github Issues](https://img.shields.io/github/issues/jantman/vagrant-r10k.svg)](https://github.com/jantman/vagrant-r10k/issues)
[![Project Status: Active - The project has reached a stable, usable state and is being actively developed.](http://www.repostatus.org/badges/0.1.0/active.svg)](http://www.repostatus.org/#active)

vagrant-r10k is a [Vagrant](http://www.vagrantup.com/) 1.2+ middleware plugin to allow you to have just a Puppetfile and
manifests in your vagrant project, and pull in the required modules via [r10k](https://github.com/adrienthebo/r10k). This
plugin only works with the 'puppet' provisioner, not a puppet server. It expects you to have a Puppetfile in the same repository
as your Vagrantfile.

## Installation

    $ vagrant plugin install vagrant-r10k

__Note__ that if you include modules from a (the) forge in your Puppetfile, i.e. in the format

    mod 'username/modulename'

instead of just git references, you will need the ``puppet`` rubygem installed and available. It
is not included in the Gemfile so that users who only use git references won't have a new/possibly
conflicting Puppet installation.

## Usage

Add the following to your Vagrantfile, before the puppet section:

    config.r10k.puppet_dir = 'dir' # the parent directory that contains your module directory and Puppetfile
    config.r10k.puppetfile_path = 'dir/Puppetfile' # the path to your Puppetfile, within the repo

For the following example directory structure:

    .
    ├── README.md
    ├── Vagrantfile
    ├── docs
    │   └── foo.md
    ├── puppet
    │   ├── Puppetfile
    │   ├── manifests
    │   │   └── default.pp
    │   └── modules
    └── someproject
        └── foo.something

The configuration for r10k and puppet would look like:

    # r10k plugin to deploy puppet modules
    config.r10k.puppet_dir = "puppet"
    config.r10k.puppetfile_path = "puppet/Puppetfile"
    
    # Provision the machine with the appliction
    config.vm.provision "puppet" do |puppet|
      puppet.manifests_path = "puppet/manifests"
      puppet.manifest_file  = "default.pp"
      puppet.module_path = "puppet/modules"
    end

If you provide an array of directories in puppet.module_path, vagrant-r10k will use the first directory listed for auto configuration. If you want to let r10k use a different directory, see below.

## Usage with explicit path to module installation directory

Add the following to your Vagrantfile, before the puppet section:

    config.r10k.puppet_dir = 'dir' # the parent directory that contains your module directory and Puppetfile
    config.r10k.puppetfile_path = 'dir/Puppetfile' # the path to your Puppetfile, within the repo
    config.r10k.module_path = 'dir/moduledir' # the path where r10k should install its modules (should be same / one of those in puppet provisioner, will be checked)

For the following example directory structure:

    .
    ├── README.md
    ├── Vagrantfile
    ├── docs
    │   └── foo.md
    ├── puppet
    │   ├── Puppetfile
    │   ├── manifests
    │   │   └── default.pp
    │   ├── modules # your own modules
    │   └── vendor # modules installed by r10k
    └── someproject
	└── foo.something

The configuration for r10k and puppet would look like:

    # r10k plugin to deploy puppet modules
    config.r10k.puppet_dir = "puppet"
    config.r10k.puppetfile_path = "puppet/Puppetfile"
    config.r10k.module_path = "puppet/vendor"
    
    # Provision the machine with the appliction
    config.vm.provision "puppet" do |puppet|
      puppet.manifests_path = "puppet/manifests"
      puppet.manifest_file  = "default.pp"
      puppet.module_path = ["puppet/modules", "puppet/vendor"]
    end

## Contributing

1. Fork it ( https://github.com/jantman/vagrant-r10k/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Add yourself to the "Contributors" list below.
5. Push to the branch (`git push origin my-new-feature`)
6. Create a new Pull Request

### Contributors

* Oliver Bertuch - [https://github.com/poikilotherm](https://github.com/poikilotherm)

## Testing

Still need to write tests... but they'll be using bundler and rspec.

__Note__ that developming vagrant plugins _requires_ ruby 2.0.0 or newer.
A `.ruby-version` is provided to get [rvm](https://rvm.io/workflow/projects)
to use 2.1.1.

For manual testing:

    bundle install --path vendor
	VAGRANT_LOG=debug bundle exec vagrant up

To use an existing project's Vagrantfile, you can just specify the directory that the Vagrantfile
is in using the ``VAGRANT_CWD`` environment variable (i.e. prepend ``VAGRANT_CWD=/path/to/project``
to the above command).

## Debugging

Exporting ``VAGRANT_LOG=debug`` will also turn on debug-level logging for r10k.

## Releasing

1. Ensure all tests are passing, coverage is acceptable, etc.
2. Increment the version number in ``lib/vagrant-r10k/version.rb``
3. Update CHANGES.md
4. Push those changes to origin.
5. ``bundle exec rake build``
6. ``bundle exec rake release``

## Acknowlegements

Thanks to the following people:

* [@adrienthebo](https://github.com/adrienthebo) for [r10k](https://github.com/adrienthebo/r10k) and for [vagrant-pe_build](https://github.com/adrienthebo/vagrant-pe_build) as a wonderful example of unit testing Vagrant plugins.
* [@garethr](https://github.com/garethr) for [librarian-puppet-vagrant](https://github.com/garethr/librarian-puppet-vagrant) which inspired this plugin
* [Alex Kahn](http://akahn.net/) of Paperless Post for his [How to Write a Vagrant Middleware](http://akahn.net/2014/05/05/vagrant-middleware.html) blog post, documenting the new middleware API
