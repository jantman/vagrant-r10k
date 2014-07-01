# Vagrant::R10k

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
    │   └── foo.md
    ├── puppet
    │   ├── Puppetfile
    │   ├── manifests
    │   │   └── default.pp
    │   └── modules
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

## Contributing

1. Fork it ( https://github.com/jantman/vagrant-r10k/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Testing

Still need to write tests... but they'll be using bundler and rspec.

## Debugging

Exporting ``VAGRANT_LOG=debug`` will also turn on debug-level logging for r10k.

## Acknowlegements

Thanks to the following people:

* [@adrienthebo](https://github.com/adrienthebo) for [r10k](https://github.com/adrienthebo/r10k)
* [@garethr](https://github.com/garethr) for [librarian-puppet-vagrant](https://github.com/garethr/librarian-puppet-vagrant) which inspired this plugin
* [Alex Kahn](http://akahn.net/) of Paperless Post for his [How to Write a Vagrant Middleware](http://akahn.net/2014/05/05/vagrant-middleware.html) blog post, documenting the new middleware API
