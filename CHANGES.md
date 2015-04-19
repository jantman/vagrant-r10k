# vagrant-r10k changelog

## master (unreleased)

* Use relative requires in ``plugin.rb``
* Change gemspec from ``bundler ~> 1.6`` to ``bundler ~> 1.5`` for testing Vagrant 1.5.0
* Testing changes
  * Ignore ``spec/`` in coverage
  * Add increased coverage of ``plugin.rb``
  * Change to documentation output for rspec
  * Don't gitignore ``Gemfile.lock``
  * Randomize test execution order
  * Add JUnit XML results output
  * Ignore some un-testable code from coverage analysis
  * Add Travis testing for Vagrant 1.5.0

## 0.2.0 2015-01-10 Jason Antman <jason@jasonantman.com>

* Add unit tests for modulegetter and config.
* Readme updates.
* Add changelog.
* Fix bug in newer Vagrant where provider does not have .name ([issue #3](https://github.com/jantman/vagrant-r10k/issues/3))
* Update README.md

## 0.1.1 2014-08-07 Jason Antman <jason@jasonantman.com>

* Add support for optional config of r10k module_path and check if it is defined ([Oliver Bertuch](https://github.com/poikilotherm)).
* Add documentation
* Add default Rake task to list available tasks
* Add development docs and `.ruby_version`.
* Update contributing docs and contributors list.

## 0.1.0 2014-07-01 Jason Antman <jason@jasonantman.com>

* Initial Release
