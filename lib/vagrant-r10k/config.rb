require "log4r"

module VagrantPlugins
  module R10k
    # vagrant-r10k plugin configuration
    class Config < Vagrant.plugin('2', :config)
      attr_accessor :puppet_dir
      attr_accessor :puppetfile_path
      attr_accessor :module_path

      # initialize config
      def initialize
        @puppet_dir = UNSET_VALUE
        @puppetfile_path = UNSET_VALUE
        @module_path = UNSET_VALUE
        @logger = Log4r::Logger.new("vagrant::r10k::config")
        @logger.debug("vagrant-r10k-config: initialize")
      end

      # validate configuration
      def validate(machine)
        @logger.debug("vagrant-r10k-config: validate")
        errors = _detected_errors

        return {} if puppet_dir == UNSET_VALUE and puppetfile_path == UNSET_VALUE

        if puppet_dir == UNSET_VALUE
          errors << "config.r10k.puppet_dir must be set"
          return { "vagrant-r10k" => errors }
        end

        puppet_dir_path = File.join(machine.env.root_path, puppet_dir)
        errors << "puppet_dir directory '#{puppet_dir_path}' does not exist" unless File.directory?(puppet_dir_path)

        if puppetfile_path == UNSET_VALUE
          errors << "config.r10k.puppetfile_path must be set"
          return { "vagrant-r10k" => errors }
        end

        puppetfile = File.join(machine.env.root_path, puppetfile_path)
        errors << "puppetfile '#{puppetfile}' does not exist" unless File.file?(puppetfile)

        if module_path != UNSET_VALUE
          module_path_path = File.join(machine.env.root_path, module_path)
          errors << "module_path directory '#{module_path_path}' does not exist" unless File.directory?(module_path_path)
        end

        @logger.debug("vagrant-r10k-config: END validate")
        { "vagrant-r10k" => errors }
      end

    end
  end
end
