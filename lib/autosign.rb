require 'rubygems'
require 'json'
require 'autosign/version.rb'
require 'autosign/token.rb'
require 'autosign/config.rb'
require 'autosign/decoder.rb'
require 'autosign/journal.rb'
require 'autosign/validator.rb'

# Add requires for other files you add to your project here, so
# you just need to require this one file in your bin file

# Autosign facilitates SSL certificate autosigning in Puppet.
# The overall flow of data is:
#
# When executed by puppet to validate certificate signing requests:
#
# 1. Puppet runs bin/autosign-validator with the requested certname as the parameter and the X509 CSR in STDIN
# 2. bin/autosign-validator uses Autosign::Decoder to extract key data from the CSR, then
# 3. Uses Autosign::Validator.any_validator to send the CSR to each available validator.
# 4. Autosign::Validator.any_validator calls each of its' child classes, and returns true if any validator succeeds.
# 5. bin/autosign-validator exits with exit code 0 if validation succeeded, or exit code 1 if validation failed.
#
module Autosign
  # this section is only here as a stub to allow documentation of the overall module/gem in yardoc format.
end
