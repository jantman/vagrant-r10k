require 'r10k/logging'
require 'vagrant/errors'
require "log4r"

# this is an ugly monkeypatch, since we're running inside of Vagrant,
# which has already defined logger but not with the debug1 and debug2 custom levels
module Log4r
  class Logger

    def debug1(msg)
      self.debug(msg)
    end
    def debug2(msg)
      self.debug(msg)
    end
  end
end

# patch this so we can get programmatic access to the errors
module R10K
  class TaskRunner
    def get_errors
      @errors
    end
  end
end

module VagrantPlugins
  module R10k
    class Modulegetter
      include R10K::Logging
      def initialize(app, env)
        @app = app
        @logger = Log4r::Logger.new("vagrant::r10k::modulegetter")
        #@logger.level = 0
      end

      def call(env)
        @logger.debug("vagrant-r10k: called")
        require 'r10k/puppetfile'
        require 'r10k/task_runner'
        require 'r10k/task/puppetfile'

        @env = env
        env_dir = @env[:root_path]

        # since this plugin runs in a hackish way (to force it to be before puppet provisioner's
        # config validation), check here that our config items are set, else bail out 
        unset = Vagrant::Plugin::V2::Config::UNSET_VALUE
        if @env[:machine].config.r10k.puppet_dir == unset or @env[:machine].config.r10k.puppetfile_path == unset
          @env[:ui].detail "vagrant-r10k: puppet_dir and/or puppetfile_path not set in config; not running"
          @app.call(env)
          return
        end

        puppetfile_path = File.join(env_dir, @env[:machine].config.r10k.puppetfile_path)
        @logger.debug("vagrant-r10k: puppetfile_path: #{puppetfile_path}")

        module_path = nil
        # override the default mechanism for building a module_path with the optional config argument
        if @env[:machine].config.r10k.module_path != unset
          module_path = @env[:machine].config.r10k.module_path
          @logger.debug("vagrant-r10k: module_path: #{module_path}")
        end

        manifest_file = nil
        manifests_path = nil
        @env[:machine].config.vm.provisioners.each do |prov|
          if prov.respond_to?(:type)
            next if prov.type != :puppet
          else
            next if prov.name != :puppet
          end
          # if module_path has been set before, check if it fits to one defined in the provisioner config
          if module_path != nil
            if prov.config.module_path.is_a?(Array) and ! prov.config.module_path.include?(module_path) 
              @env[:ui].detail "vagrant-r10k: module_path \"#{module_path}\" is not within the ones defined in puppet provisioner; not running"
              @app.call(env)
              return
            elsif ! prov.config.module_path.is_a?(Array) and prov.config.module_path != module_path
              @env[:ui].detail "vagrant-r10k: module_path \"#{module_path}\" is not the same as in puppet provisioner; not running"
              @app.call(env)
              return
            end
          # no modulepath explict set in config, build one from the provisioner config
          else
            module_path = prov.config.module_path.is_a?(Array) ? prov.config.module_path[0] : prov.config.module_path
            @env[:ui].info "vagrant-r10k: Building the r10k module path with puppet provisioner module_path \"#{module_path}\". (if module_path is an array, first element is used)"
          end

          manifest_file = File.join(env_dir, prov.config.manifest_file)
          manifests_path = File.join(env_dir, prov.config.manifests_path[1])
        end

        # now join the module_path with the env_dir to have an absolute path
        module_path = File.join(env_dir, module_path)
        @env[:ui].info "vagrant-r10k: Beginning r10k deploy of puppet modules into #{module_path} using #{puppetfile_path}"

        if ENV["VAGRANT_LOG"] == "debug"
          R10K::Logging.level = 0
        else
          R10K::Logging.level = 3
        end

        if !File.file?(puppetfile_path)
          raise ErrorWrapper.new(RuntimeError.new("Puppetfile at #{puppetfile_path} does not exist."))
        end

        # do the actual module buildout
        runner = R10K::TaskRunner.new([])
        begin
          @logger.debug("vagrant-r10k: instantiating R10K::Puppetfile")
          puppetfile = R10K::Puppetfile.new(File.join(env_dir, @env[:machine].config.r10k.puppet_dir), module_path, puppetfile_path)
          @logger.debug("vagrant-r10k: creating Puppetfile::Sync task")
          task   = R10K::Task::Puppetfile::Sync.new(puppetfile)
          @logger.debug("vagrant-r10k: appending task to runner queue")
          runner.append_task task
          @logger.debug("vagrant-r10k: running sync task")
          runner.run
          @logger.debug("vagrant-r10k: sync task complete")
        rescue SyntaxError => ex
          @env[:ui].error "Invalid syntax in Puppetfile at #{puppetfile_path}"
          raise ErrorWrapper.new(ex)
        end
        if !runner.succeeded?
          runner.get_errors().each do |error|
            raise ErrorWrapper.new(RuntimeError.new(error[1]))
          end
        end
        @env[:ui].info "vagrant-r10k: Deploy finished"
        @app.call(env)
      end

    end

    class ErrorWrapper < ::Vagrant::Errors::VagrantError
      attr_reader :original

      def initialize(original)
        @original = original
      end

      def to_s
        "#{original.class}: #{original.to_s}"
      end

      private

      def method_missing(fun, *args, &block)
        original.send(fun, *args, &block)
      end

    end

  end
end
