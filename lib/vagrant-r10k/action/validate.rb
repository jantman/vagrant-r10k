require_relative 'base'

module VagrantPlugins
  module R10k
    module Action
      # action to validate config pre-deploy
      class Validate < Base

        # validate configuration pre-deploy
        def call(env)
          @logger.debug "vagrant::r10k::validate called"

          unless r10k_enabled?(env)
            env[:ui].info "vagrant-r10k not configured; skipping"
            return @app.call(env)
          end

          unless provision_enabled?(env)
            env[:ui].info "provisioning disabled; skipping vagrant-r10k"
            return @app.call(env)
          end

          config = r10k_config(env)
          if config.nil?
            @logger.info "vagrant::r10k::deploy got nil configuration"
            raise ErrorWrapper.new(RuntimeError.new("vagrant-r10k configuration error; cannot continue"))
          end

          puppetfile = get_puppetfile(config)

          # validate puppetfile
          @logger.debug "vagrant::r10k::validate: validating Puppetfile at #{config[:puppetfile_path]}"
          begin
            puppetfile.load
          rescue Exception => ex
            @env[:ui].error "Invalid syntax in Puppetfile at #{config[:puppetfile_path]}"
            raise ErrorWrapper.new(ex.original)
          end

          @app.call(env)
        end

      end
    end
  end
end
