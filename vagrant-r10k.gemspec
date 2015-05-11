# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vagrant-r10k/version'

Gem::Specification.new do |spec|
  spec.name          = "vagrant-r10k"
  spec.version       = VagrantPlugins::R10k::VERSION
  spec.platform      = Gem::Platform::RUBY
  spec.authors       = ["Jason Antman"]
  spec.email         = ["jason@jasonantman.com"]
  spec.summary       = %q{Vagrant middleware plugin to retrieve puppet modules using r10k.}
  spec.description   = %q{Vagrant middleware plugin to allow you to have just a Puppetfile and manifests in your vagrant project, and pull in the required modules via r10k.}
  spec.homepage      = "https://github.com/jantman/vagrant-r10k"
  spec.license       = "Apache-2.0"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "r10k", "~> 1.2.1"

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
end
