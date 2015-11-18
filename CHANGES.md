# vagrant-r10k changelog

## master (unreleased)

## 0.4.1 2015-11-18 Jason Antman <jason@jasonantman.com>

* [#36](https://github.com/jantman/vagrant-r10k/issues/36) - Fix "no implicit conversion of nil into String" issue with puppet4, caused by ``config.r10k.manifest_file`` and/or ``config.r10k.manifests_path`` not being specified. This removes all use of these parameters, which were only used in log messages. It also removes validation that the Puppet provisioner's ``module_path`` matches that specified for r10k.
* Fix ``.ruby-version`` (2.1.0 to 2.1.1)
* Add ``.rebuildbot.sh`` for [rebuildbot](https://github.com/jantman/rebuildbot) testing

## 0.4.0 2015-10-29 Jason Antman <jason@jasonantman.com>

* [#13](https://github.com/jantman/vagrant-r10k/issues/13) / [PR #34/35](https://github.com/jantman/vagrant-r10k/pull/35) - Upgrade r10k dependency to 1.5.1 (thanks to [@cdenneen](https://github.com/cdenneen) for the work).

## 0.3.0 2015-09-04 Jason Antman <jason@jasonantman.com>

* [#9](https://github.com/jantman/vagrant-r10k/issues/9) major refactor to separate config validation and provisioning, and prevent multiple provisioning runs
* [#15](https://github.com/jantman/vagrant-r10k/issues/17) document how to install Forge modules
* [#16](https://github.com/jantman/vagrant-r10k/issues/16) more helpful error message if r10k deploy fails with 'Could not resolve host'
* Change gemspec from ``bundler ~> 1.6`` to ``bundler ~> 1.5`` for testing Vagrant 1.5.0
* Updates to ``README.md``
* Testing changes
  * [#12](https://github.com/jantman/vagrant-r10k/issues/12) [vagrant-spec](https://github.com/mitchellh/vagrant-spec/)-based acceptance tests for VirtualBox
  * [#20](https://github.com/jantman/vagrant-r10k/issues/20) vmware-workstation spec tests are broken and disabled
  * Major overhaul to spec and acceptance tests
  * Ignore ``spec/`` in coverage
  * Add increased coverage of ``plugin.rb``
  * Change to documentation output for rspec
  * Don't gitignore ``Gemfile.lock``
  * Randomize test execution order
  * Add JUnit XML results output
  * Ignore some un-testable code from coverage analysis
  * Add Travis testing for Vagrant 1.5.0
  * Add ``--retry`` to ``bundle install`` to fix Travis timeout errors
  * Downgrade bundler from 1.6 to 1.5 to work with older testing versions
  * Bump bundled Vagrant version from 1.7.2 to 1.7.4
  * [#22](https://github.com/jantman/vagrant-r10k/issues/22) enable pullreview.com code analysis and comments, and make some recommended changes

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
