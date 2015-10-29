require_relative 'base'

module VagrantPlugins
  module R10k
    module Action
      # run r10k deploy
      class Deploy < Base

        # determine if we should run, and get config
        def call(env)
          @logger.debug "vagrant::r10k::deploy called"

          unless r10k_enabled?(env)
            env[:ui].info "vagrant-r10k not configured; skipping"
            return @app.call(env)
          end

          unless provision_enabled?(env)
            env[:ui].info "provisioning disabled; skipping vagrant-r10k"
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

        # run the actual r10k deploy
        def deploy(env, config)
          @logger.debug("vagrant::r10k::deploy.deploy called")
          require 'r10k/task_runner'
          require 'r10k/task/puppetfile'

          env[:ui].info "vagrant-r10k: Beginning r10k deploy of puppet modules into #{config[:module_path]} using #{config[:puppetfile_path]}"

          if ENV["VAGRANT_LOG"] == "debug"
            R10K::Logging.level = 'debug'
          else
            R10K::Logging.level = 'info'
          end

          unless File.file?(config[:puppetfile_path])
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
          rescue Exception => ex
            @env[:ui].error "Invalid syntax in Puppetfile at #{config[:puppetfile_path]}"
            raise ErrorWrapper.new(ex.original)
          end
          unless runner.succeeded?
            runner.get_errors().each do |error|
              if error[1].message.include?("fatal: unable to access") and error[1].message.include?("Could not resolve host")
                # if we can't resolve the host, the error should include how to skip provisioning
                @logger.debug("vagrant-r10k: caught 'Could not resolve host' error")
                raise ErrorWrapper.new(RuntimeError.new(error[1].message + "\n\nIf you don't have connectivity to the host, running 'vagrant up --no-provision' will skip r10k deploy and all provisioning."))
              else
                raise ErrorWrapper.new(RuntimeError.new(error[1]))
              end
            end
          end
          @env[:ui].info "vagrant-r10k: Deploy finished"
          @app.call(env)
        end
      end
    end
  end
end
