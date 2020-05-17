# frozen_string_literal: true

require 'logging'
require 'require_all'

module Autosign
  module Validator
    
    # @return [Array] - A list of all the validator classes
    # @param list [Array] - a list of validators to use, uses the settings list by default
    # This returns a list of validators that were specified by the user and the exact
    # order they want the validation to procede.
    def self.validation_order(list = nil)
      validation_order = list || Autosign::Config.new.settings['general']['validation_order']
      # create a key pair where the key is the name of the validator and value is the class
      validator_list = validator_classes.each_with_object({}) do |klass, acc|
        acc[klass::NAME] = klass
        acc
      end
      # filter out validators that do not exist
      validation_order.map { |v| validator_list.fetch(v, nil) }.compact
    end

    # @summary
    # Class method to attempt validation of a request against all validators which inherit from this class.
    # The request is considered to be validated if any one validator succeeds.
    # The first validator to pass shorts the validation process so other validators are not called.
    # @param challenge_password [String] the challenge_password OID from the certificate signing request
    # @param certname [String] the common name being requested in the certificate signing request
    # @param raw_csr [String] the encoded X509 certificate signing request, as received by the autosign policy executable
    # @return [Boolean] return true if the certificate should be signed, and false if it cannot be validated
    def self.any_validator(challenge_password, certname, raw_csr)
      @log = Logging.logger[self.class]
      # find the first validator that passes and return the class
      validator = validation_order.find { |c| c.new.validate(challenge_password, certname, raw_csr) }
      if validator
        @log.info "Successfully validated using #{validator::NAME}"
        true
      else
        @log.info 'unable to validate using any validator'
        false
      end
    end

    private

    # Find other classes that inherit from this class.
    # Used to discover autosign validators. There is probably no reason to use
    # this directly.
    # @return [Array] of classes inheriting from Autosign::Validator
    def self.validator_classes
      validators = Dir.glob(File.join(__dir__, 'validators', '*')).sort.each {|k| require k }
      ObjectSpace.each_object(Class).select { |klass| klass < Autosign::Validators::ValidatorBase }
    end
  end
end
