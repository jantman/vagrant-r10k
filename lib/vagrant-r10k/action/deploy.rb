require_relative 'base'

module VagrantPlugins
  module R10k
    module Action
      class Deploy < Base

        def call(env)
          @logger.debug "vagrant::r10k::deploy called"

          if !r10k_enabled?(env)
            @logger.info "r10k not configured; skipping vagrant-r10k"
            return @app.call(env)
          end

          if !provision_enabled?(env)
            @logger.info "provisioning disabled; skipping vagrant-r10k"
            return @app.call(env)
          end

          # get our config
          config = r10k_config(env)
          if config.nil?
            @logger.info "vagrant::r10k::deploy got nil configuration"
            raise ErrorWrapper.new(RuntimeError.new("vagrant-r10k configuration error; cannot continue"))
          end
          @logger.debug("vagrant::r10k::deploy: env_dir_path=#{config[:env_dir_path]}")
          @logger.debug("vagrant::r10k::deploy: puppetfile_path=#{config[:puppetfile_path]}")
          @logger.debug("vagrant::r10k::deploy: module_path=#{config[:module_path]}")
          @logger.debug("vagrant::r10k::deploy: manifests=#{config[:manifests]}")
          @logger.debug("vagrant::r10k::deploy: manifest_file=#{config[:manifest_file]}")
          @logger.debug("vagrant::r10k::deploy: puppet_dir=#{config[:puppet_dir]}")

          deploy(env, config)

          @app.call(env)
        end

        def deploy(env, config)
          @logger.debug("vagrant-r10k: called")
          require 'r10k/task_runner'
          require 'r10k/task/puppetfile'

          env[:ui].info "vagrant-r10k: Beginning r10k deploy of puppet modules into #{config[:module_path]} using #{config[:puppetfile_path]}"

          if ENV["VAGRANT_LOG"] == "debug"
            R10K::Logging.level = 0
          else
            R10K::Logging.level = 3
          end

          if !File.file?(config[:puppetfile_path])
            raise ErrorWrapper.new(RuntimeError.new("Puppetfile at #{config[:puppetfile_path]} does not exist."))
          end

          # do the actual module buildout
          runner = R10K::TaskRunner.new([])
          begin
            puppetfile = get_puppetfile(config)
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
end
