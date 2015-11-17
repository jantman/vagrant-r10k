#!/bin/bash -ex

set +x
. ~/.rvm/scripts/rvm
rvm use $(cat .ruby-version)
rvm info
which ruby
ruby -v
set -x

export VAGRANT_VERSION=1.7.4
bundle install --path vendor
bundle exec rake acceptance:virtualbox
