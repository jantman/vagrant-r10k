require_relative 'base'

module VagrantPlugins
  module R10k
    module Action
      class Validate < Base

        def call(env)
          @logger.debug "vagrant::r10k::validate called"

          if !r10k_enabled?(env)
            env[:ui].info "vagrant-r10k not configured; skipping"
            return @app.call(env)
          end

          if !provision_enabled?(env)
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
            @logger.error "ERROR: Puppetfile bad syntax"
            raise ErrorWrapper.new(RuntimeError.new(ex))
          end

          @app.call(env)
        end

      end
    end
  end
end
