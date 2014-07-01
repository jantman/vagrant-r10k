module VagrantPlugins
  module R10k
    class Config < Vagrant.plugin('2', :config)
      attr_accessor :puppet_dir
      attr_accessor :puppetfile_path

      def initialize
        @puppet_dir = UNSET_VALUE
        @puppetfile_path = UNSET_VALUE
      end

      def validate(machine)
        errors = _detected_errors

        return {} if puppet_dir == UNSET_VALUE and puppetfile_path == UNSET_VALUE

        if puppet_dir == UNSET_VALUE
          errors << "config.r10k.puppet_dir must be set"
          return { "vagrant-r10k" => errors }
        end

        puppet_dir_path = File.join(machine.env.root_path, puppet_dir)
        errors << "puppet_dir directory '#{puppet_dir_path}' does not exist" if !File.directory?(puppet_dir_path)

        if puppetfile_path == UNSET_VALUE
          errors << "config.r10k.puppetfile_path must be set"
          return { "vagrant-r10k" => errors }
        end

        puppetfile = File.join(machine.env.root_path, puppetfile_path)
        errors << "puppetfile '#{puppetfile}' does not exist" if !File.file?(puppetfile)

        { "vagrant-r10k" => errors }
      end

    end
  end
end
