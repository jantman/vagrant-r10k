# Vagrant::R10k

vagrant-r10k is a `Vagrant <http://www.vagrantup.com/>`_ 1.2+ middleware plugin to allow you to have just a Puppetfile and
manifests in your vagrant project, and pull in the required modules via `r10k <https://github.com/adrienthebo/r10k>`_. This
plugin only works with the 'puppet' provisioner, not a puppet server. It expects you to have a Puppetfile in the same repository
as your Vagrantfile.

## Installation

    $ vagrant plugin install vagrant-r10k

## Usage

Add the following to your Vagrantfile, before the puppet section:


## Contributing

1. Fork it ( https://github.com/jantman/vagrant-r10k/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Debugging

Exporting ``VAGRANT_LOG=debug`` will also turn on debug-level logging for r10k.

## Acknowlegements

Thanks to the following people:

* `@adrienthebo <https://github.com/adrienthebo>`_ for `r10k <https://github.com/adrienthebo/r10k>`_
* `@garethr <https://github.com/garethr>`_ for `librarian-puppet-vagrant <https://github.com/garethr/librarian-puppet-vagrant>`_ which inspired this plugin
* `Alex Kahn <http://akahn.net/>`_ of Paperless Post for his `How to Write a Vagrant Middleware <http://akahn.net/2014/05/05/vagrant-middleware.html>`_ blog post, documenting the new middleware API
