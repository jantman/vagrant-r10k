require 'r10k/logging'
require 'vagrant/errors'

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
      end

      def call(env)
        require 'r10k/puppetfile'
        require 'r10k/task_runner'
        require 'r10k/task/puppetfile'
        @env = env
        env_dir = @env[:root_path]
        puppetfile_path = File.join(env_dir, @env[:machine].config.r10k.puppetfile_path)
        module_path = nil
        manifest_file = nil
        manifests_path = nil
        @env[:machine].config.vm.provisioners.each do |prov|
          if prov.name == :puppet
            module_path = File.join(env_dir, prov.config.module_path)
            manifest_file = File.join(env_dir, prov.config.manifest_file)
            manifests_path = File.join(env_dir, prov.config.manifests_path[1])
          end
        end

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
          puppetfile = R10K::Puppetfile.new(File.join(env_dir, @env[:machine].config.r10k.puppet_dir), module_path, puppetfile_path)
          task   = R10K::Task::Puppetfile::Sync.new(puppetfile)
          runner.append_task task
          runner.run
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
