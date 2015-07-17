# autosign
[![Build Status](https://travis-ci.org/danieldreier/autosign.svg?branch=master)](https://travis-ci.org/danieldreier/autosign) [![Code Climate](https://codeclimate.com/github/danieldreier/autosign/badges/gpa.svg)](https://codeclimate.com/github/danieldreier/autosign) [![Dependency Status](https://gemnasium.com/danieldreier/autosign.svg)](https://gemnasium.com/danieldreier/autosign) [![Yard Docs](http://img.shields.io/badge/yard-docs-blue.svg)](http://rubydoc.info/github/danieldreier/autosign) [![Inline docs](http://inch-ci.org/github/danieldreier/autosign.png)](http://inch-ci.org/github/danieldreier/autosign) [![Coverage Status](https://coveralls.io/repos/danieldreier/autosign/badge.svg?branch=master&service=github)](https://coveralls.io/github/danieldreier/autosign?branch=master) [![Gem Version](https://badge.fury.io/rb/autosign.svg)](http://badge.fury.io/rb/autosign)

Tooling to make puppet autosigning easy, secure, and extensible

### Introduction

This tool provides a CLI for performing puppet policy-based autosigning using JWT tokens. Read more at https://danieldreier.github.io/autosign.

### Quick Start: How to Generate Tokens

##### 1. Install Gem on Puppet Master
```shell
gem install autosign
```

##### 2. Generate default configuration

```shell
autosign config setup
```

##### 3. Generate your first autosign token on the puppet master
```shell
autosign generate foo.example.com
```

The output will look something like
```
Autosign token for: foo.example.com, valid until: 2015-07-16 16:25:50 -0700
To use the token, put the following in ${puppet_confdir}/csr_attributes.yaml prior to running puppet agent for the first time:

custom_attributes:
  challengePassword: "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJkYXRhIjoie1wiY2VydG5hbWVcIjpcImZvby5leGFtcGxlLmNvbVwiLFwicmVxdWVzdGVyXCI6XCJEYW5pZWxzLU1hY0Jvb2stUHJvLTIubG9jYWxcIixcInJldXNhYmxlXCI6ZmFsc2UsXCJ2YWxpZGZvclwiOjcyMDAsXCJ1dWlkXCI6XCJkM2YyNzI0OC1jZDFmLTRhZmItYjI0MC02ZjBjMDU4NWJiZDNcIn0iLCJleHAiOiIxNDM3MDg5MTUwIn0.lC-EzWaV2dL81aLL7P-9mGwNbiOQDJWcoYjuSHVOqmaLtc7Wis5OZvHFOLln2Fn9qv98oSTnZsIkjmFpbI5dvA"
  ```

The resulting output can be copied to `/etc/puppet/csr_attributes.yaml` on an agent machine prior to running puppet for the first time to add the token to the CSR as the `challengePassword` OID. (just copy-paste from one terminal to another to copy the text)

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

```yaml
multiplexer:
  external_policy_executable: "/path/to/autosign/executable"
```

The master will validate the certificate if either the token validator or the external validator succeeds.

If the autosign script was just validating simple strings, you can use the `password_list` validator instead. For example, to configure the master to sign any CSR that includes the challenge passwords of "hunter2" or "CPE1704TKS" you would add:

```ini
password_list:
  password: "hunter2"
  password: "CPE1704TKS"
```

Note that this is a relatively insecure way to do certificate autosigning. Using one-time tokens via the `autosign generate` command is more secure. This functionality is provided to grandfather in existing use cases to ease the transition.


### Troubleshooting
If you're having problems, try the following:

- Set `loglevel: "debug"` in `/etc/autosign.conf`
- Check the `journalfile`, in `/var/autosign/autosign.journal` by default, to see if the one-time token's UUID has already been recorded. It's just YAML, so you can either delete it or remove the offending entry if you actually want to re-use a token.
- you can manually trigger the autosigning script with something like `cat the_csr.csr | autosign-validator certname.example.com`
- If you run the puppet master foregrounded, you'll see quite a bit of autosign script output if autosign loglevel is set to debug.


### Further Reading

- [https://danieldreier.github.io/autosign](https://danieldreier.github.io/autosign) has background on why this exists.
- Automatically generated code documentation in YARDOC format is [available on rubydoc.info](http://rubydoc.info/github/danieldreier/autosign).
- Look at the [puppet-autosign](https://travis-ci.org/danieldreier/puppet-autosign) puppet module to automate setup of this tool, and for a puppet function to generate tokens inside of Puppet, for example when provisioning systems in AWS.
