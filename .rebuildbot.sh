#!/bin/bash -x
export VAGRANT_VERSION=1.7.4
bundle install --path vendor
bundle exec rake acceptance:virtualbox
