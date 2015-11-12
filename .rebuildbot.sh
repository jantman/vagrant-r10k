#!/bin/bash -ex

rvm use $(cat .ruby-version)
rvm info
which ruby
ruby -v

export VAGRANT_VERSION=1.7.4
bundle install --path vendor
bundle exec rake acceptance:virtualbox
