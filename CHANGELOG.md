# Augosign changelog

## Unreleased

## 1.0.1
* (maint) Remove gem dependency on 2.4

## 1.0.0
Released May 19, 2020 

* (maint) print config in yaml format
* (maint) Fix a cache bug where the settings were loaded multiple times
* (maint) Fix a bug where the config overwrites settings
* (maint) Fix bug with validation order
* (maint) The autosign gem now requires the deep_merge gem 1.2.1
* (maint) The require_all has been dropped and is no longer a dependency
* (maint) Fix deprecation warnings with gemspec file
* (maint) Objectify the validator classes
* (maint) Fix a cache bug where the settings were loaded multiple times.
    This was causing overzealous logging
* (feat) Add an ordered validator list
* (feat) Any validator should short circuit
* (feat) Allow user to specify validation order

This release removes support for ruby < 2.4.

## 0.1.4
Released Nov 25, 2019 

### Bug fixes

* Use multi_json to allow a variety of JSON engines to be used, which makes installation easier.
* Read all of STDIN regardless of whether we’ll use it in order to avoid a bug in Java 8.
* Change yard from a runtime dependency to a dev dependency.
* Security updates for dependencies:
* Bump ffi from 1.9.10 to 1.9.25
* Bump yard from 0.9.12 to 0.9.20

## 0.1.3
Released Jan 24, 2018

### Bug fixes

* Fix config file path; the latest version of puppet-autosign creates config files in /etc/puppetlabs/puppetserver/autosign.conf but we weren't checking there
* @reidmv fixed a bug where the decoder would error when presented with a csr with no challengePassword
* added an Apache license to be explicit about how the code is licensed. Did check with all contributors first.

## 0.1.1
Released Oct 30, 2015

* bump version to 0.1.1 to fix safe_yaml issue

## 0.0.6 
Released Jul 15, 2015

* add autosign-validator executable to gem
