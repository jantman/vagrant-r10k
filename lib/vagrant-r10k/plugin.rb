begin
  require "vagrant"
rescue LoadError
  abort "vagrant-r10k must be loaded in a Vagrant environment."
end

if Vagrant::VERSION < "1.2.0"
  raise "The Vagrant r10k plugin is only compatible with Vagrant 1.2+"
end

require_relative "version"
require_relative "modulegetter"

module VagrantPlugins
  module R10k
    class Plugin < Vagrant.plugin('2')
      name "vagrant-r10k"
      description "Retrieve puppet modules based on a Puppetfile"

      action_hook "vagrant-r10k" do |hook|
        hook.before Vagrant::Action::Builtin::Provision, Modulegetter
        hook.before Vagrant::Action::Builtin::ConfigValidate, Modulegetter
      end

      config "r10k" do
        require_relative "config"
        Config
      end

    end
  end
end
