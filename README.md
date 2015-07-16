# autosign
[![Build Status](https://travis-ci.org/danieldreier/autosign.svg?branch=master)](https://travis-ci.org/danieldreier/autosign) [![Code Climate](https://codeclimate.com/github/danieldreier/autosign/badges/gpa.svg)](https://codeclimate.com/github/danieldreier/autosign) [![Dependency Status](https://gemnasium.com/danieldreier/autosign.svg)](https://gemnasium.com/danieldreier/autosign) [![Yard Docs](http://img.shields.io/badge/yard-docs-blue.svg)](http://rubydoc.info/github/danieldreier/autosign) [![Inline docs](http://inch-ci.org/github/danieldreier/autosign.png)](http://inch-ci.org/github/danieldreier/autosign) [![Coverage Status](https://coveralls.io/repos/danieldreier/autosign/badge.svg?branch=master&service=github)](https://coveralls.io/github/danieldreier/autosign?branch=master) [![Gem Version](https://badge.fury.io/rb/autosign.svg)](http://badge.fury.io/rb/autosign)

Tooling to make puppet autosigning easy, secure, and extensible

### Introduction

This tool provides a CLI for performing puppet policy-based autosigning using JWT tokens. Read more at https://danieldreier.github.io/autosign.

### Quick Start: How to Generate Tokens

##### 1. Install Gem
```shell
gem install autosign
```

##### 2. Generate default configuration

```shell
autosign config setup
```

##### 3. Generate your first autosign token
```shell
autosign foo.example.com
```

The resulting output can be copied to `/etc/puppet/csr_attributes.yaml` prior to running puppet for the first time to add the token to the CSR as the `challengePassword` OID.

### Quick Start: Puppet Master Configuration

Run through the previous quick start steps to get the gem installed, then configure puppet to use the `autosign-validator` executable as the policy autosign command:

##### 1. Prerequisities
Note that these settings will be slightly different if you're running Puppet Enterprise, because you'll need to use the `pe-puppet` user instead of `puppet`.

```shell
mkdir /var/autosign
chown puppet:puppet /var/autosign
chmod 750 /var/autosign
touch /var/log/autosign.log
chown puppet:puppet /var/log/autosign.log
```


##### 2. Configure master
```shell
puppet config set autosign $(which autosign-validator) --section master
```

Your master is now configured to autosign using the autosign gem. 


##### 3. Using Legacy Autosign Scripts

If you already had an autosign script you want to continue using, add a setting to your `autosign.conf` like:

```ini
[multiplexer]
external_policy_executable = /path/to/autosign/executable
```

The master will validate the certificate if either the token validator or the external validator succeeds.

If the autosign script was just validating simple strings, you can use the `password_list` validator instead. For example, to configure the master to sign any CSR that includes the challenge passwords of "hunter2" or "CPE1704TKS" you would add:

```ini
[password_list]
password = hunter2
password = CPE1704TKS
```

Note that this is a relatively insecure way to do certificate autosigning. Using one-time tokens via the `autosign generate` command is more secure. This functionality is provided to grandfather in existing use cases to ease the transition.


### Troubleshooting
If you're having problems, try the following:

- Set `loglevel = debug` in `/etc/autosign.conf`
- Check the `journalfile`, in `/var/autosign/autosign.journal` by default, to see if the one-time token's UUID has already been recorded. It's just YAML, so you can either delete it or remove the offending entry if you actually want to re-use a token.
- you can manually trigger the autosigning script with something like `cat the_csr.csr | autosign-validator certname.example.com`
- If you run the puppet master foregrounded, you'll see quite a bit of autosign script output if autosign loglevel is set to debug.


### Further Reading

See [https://danieldreier.github.io/autosign](https://danieldreier.github.io/autosign) for more background on why this exists.