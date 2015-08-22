# :nocov:
begin
  require "vagrant"
rescue LoadError
  abort "vagrant-r10k must be loaded in a Vagrant environment."
end

if Vagrant::VERSION < "1.2.0"
  raise "The Vagrant r10k plugin is only compatible with Vagrant 1.2+"
end
# :nocov:

require_relative "version"
require_relative "action/base"
require_relative "action/validate"
require_relative "action/deploy"

module VagrantPlugins
  module R10k
    class Plugin < Vagrant.plugin('2')
      name "vagrant-r10k"
      description "Retrieve puppet modules based on a Puppetfile"

      [:machine_action_up, :machine_action_reload, :machine_action_provision].each do |action|
        action_hook('vagrant-r10k', action) do |hook|
          hook.after(Vagrant::Action::Builtin::ConfigValidate, Action::Base.validate)
          hook.before(Vagrant::Action::Builtin::Provision, Action::Base.deploy)
        end
      end

      config "r10k" do
        require_relative "config"
        Config
      end

    end
  end
end
