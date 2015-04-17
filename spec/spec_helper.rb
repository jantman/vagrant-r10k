$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)

# Disable Vagrant autoloading so that other plugins defined in the Gemfile for
# Acceptance tests are not loaded.
ENV['VAGRANT_NO_PLUGINS'] = '1'

require 'vagrant-spec/unit'

require 'simplecov'
SimpleCov.start do
  add_filter "/vendor/"
  add_filter "/spec/"
end

require 'codecov'
if ENV['CI']=='true'
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end


require 'vagrant-r10k'
