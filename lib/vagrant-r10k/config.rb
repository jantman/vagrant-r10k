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

        puppet_dir_path = File.join(machine.env.root_path, puppet_dir)
        if !File.directory?(puppet_dir_path)
              errors << "puppet_dir directory '#{puppet_dir_path}' does not exist"
        end

        puppetfile = File.join(machine.env.root_path, puppetfile_path)
        if !File.file?(puppetfile)
              errors << "puppetfile '#{puppetfile}' does not exist"
        end

        { "vagrant-r10k" => errors }
      end

    end
  end
end
