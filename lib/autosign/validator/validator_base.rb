# frozen_string_literal: true

require 'logging'

module Autosign
  module Validator
    # Parent class for validation backends. Validator take the
    # challenge_password and common name from a certificate signing request,
    # and perform some action to determine whether the request is valid.
    #
    # Validator also get the raw X509 CSR in case the extracted information
    # is insufficient for future, more powerful validators.
    #
    # All validators must inherit from this class, and must override several
    # methods in order to function. At a minimum, the name and perform_validation
    # methods must be implemented by child classes.
    #
    # @return Autosign::Validator::ValidatorBase instance of the Autosign::Validator::ValidatorBase class
    class ValidatorBase
      NAME = 'base'
      attr_reader :config_file_settings

      def initialize(config_file_settings = nil)
        @config_file_settings = config_file_settings
        start_logging
        settings # just run to validate settings
        setup
        # call name to ensure that the class fails immediately if child classes
        # do not implement it.
        name
      end
  
      # @return [String] name of the validator. Do not use special characters.
      # You must set the NAME constant in the sublcass
      def name
        self.class::NAME
      end
  
      # define how a validator actually validates the request.
      # This must be implemented by validators which inherit from the
      # Autosign::Validator class.
      #
      # @param challenge_password [String] the challenge_password OID from the certificate signing request. The challenge_password field is the same setting as the "challengePassword" field in a `csr_attributes.yaml` file when the CSR is generated. In a request using a JSON web token, this would be the serialized token.
      # @param certname [String] the common name being requested in the certificate signing request. Treat the certname as untrusted. This is user-submitted data that you must validate.
      # @param raw_csr [String] the encoded X509 certificate signing request, as received by the autosign policy executable. This is provided as an optional extension point, but your validator may not need to use it.
      # @return [True, False] return true if the certificate should be signed, and false if you cannot validate the request successfully.
      def perform_validation(_challenge_password, _certname, _raw_csr)
        # override this after inheriting
        # should return true to indicate success validating
        # or false to indicate that the validator was unable to validate
        raise NotImplementedError
      end
  
      # wrapper method that wraps input validation and logging around the perform_validation method.
      # Do not override or use this class in child classes. This is the class that gets called
      # on validator objects.
      def validate(challenge_password, certname, raw_csr)
        raise unless challenge_password.is_a?(String)
        raise unless certname.is_a?(String)
  
        case perform_validation(challenge_password, certname, raw_csr)
        when true
          @log.debug 'validated successfully'
          @log.info  "Validated '#{certname}' using '#{name}' validator"
          true
        when false
          @log.debug 'validation failed'
          @log.debug "Unable to validate '#{certname}' using '#{name}' validator"
          false
        else
          @log.error 'perform_validation returned a non-boolean result'
          raise 'perform_validation returned a non-boolean result'
        end
      end

      private

      # this is automatically called when the class is initialized; do not
      # override it in child classes.
      def start_logging
        @log = Logging.logger[self.class]
        @log.debug 'starting autosign validator: ' + name.to_s
      end

      # (optionally) override this method in validator child classes to perform any additional
      # setup during class initialization prior to beginning validation.
      # If you need to create a database connection, this would be a good place to do it.
      # @return [True, False] return true if setup succeeded, or false if setup failed and the validation should not continue
      def setup
        true
      end

    # provide a merged settings hash of default settings for a validator,
    # config file settings for the validator, and override settings defined in
    # the validator.
    #
    # Do not override this in child classes. If you need to set
    # custom config settings, override the get_override_settings method.
    # The section of the config file this reads from is the same as the name
    # method returns.
    #
    # @return [Hash] of config settings
    def settings
      @settings ||= begin
        @log.debug "merging settings for #{name} validator"
        setting_sources = [get_override_settings, load_config, default_settings]
        merged_settings = setting_sources.inject({}) { |merged, hash| merged.deep_merge(hash, {:overwrite_arrays => true}) }
        @log.debug 'using merged settings: ' + merged_settings.to_s
        @log.debug 'validating merged settings'
        if validate_settings(merged_settings)
          @log.debug 'successfully validated merged settings'
          merged_settings
        else
          @log.warn 'validation of merged settings failed'
          @log.warn "unable to validate settings in #{name} validator"
          raise 'settings validation error'
        end
        merged_settings
      end
    end

    # (optionally) override this from a child class to set config defaults.
    # These will be overridden by config file settings.
    #
    # Override this when inheriting if you need to set config defaults.
    # For example, if you want to pull settings from zookeeper, this would
    # be a good place to do that.
    #
    # @return [Hash] of config settings
    def default_settings
      {}
    end

    # (optionally) override this to perform validation checks on the merged
    # config hash of default settings, config file settings, and override
    # settings.
    # @return [True, False]
    def validate_settings(settings)
      settings.is_a?(Hash)
    end

    # load any required configuration from the config file.
    # Do not override this in child classes.
    # @return [Hash] configuration settings from the validator's section of the config file
    def load_config
      @log.debug 'loading validator-specific configuration'
      config_settings = @config_file_settings ||= Autosign::Config.new.settings
      if config_settings.to_hash[name].nil?
        @log.warn 'Unable to load validator-specific configuration'
        @log.warn "Cannot load configuration section named '#{name}'"
        {}
      else
        @log.debug 'Set validator-specific settings from config file: ' + config_settings.to_hash[name].to_s
        config_settings.to_hash[name]
      end
    end

    # (optionally) override this from child classes to get custom configuration
    # from a validator.
    #
    # This is how you override defaults and config file settings.
    # @return [Hash] configuration settings
    def get_override_settings
      {}
    end
  end
  end
end