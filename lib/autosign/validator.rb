require 'logging'
require 'require_all'

module Autosign
  class Validator
    def initialize()
      start_logging()
      settings() # just run to validate settings
      setup()
    end

    def name
      # override this after inheriting
      # should return a string with no spaces
      # this is the name used to reference the validator in config files
      raise NotImplementedError
    end

    def validate(challenge_password, certname, raw_csr)
      @log.debug "running validate"
      fail unless challenge_password.is_a?(String)
      fail unless certname.is_a?(String)

      case perform_validation(challenge_password, certname, raw_csr)
      when true
        @log.debug "validated successfully"
        @log.info  "Validated '#{certname}' using '#{name}' validator"
        return true
      when false
        @log.debug "validation failed"
        @log.debug "Unable to validate '#{certname}' using '#{name}' validator"
        return false
      else
        @log.error "perform_validation returned a non-boolean result"
        raise "perform_validation returned a non-boolean result"
      end
    end

    def self.any_validator(challenge_password, certname, raw_csr)
      @log = Logging.logger[self.name]
      # iterate over all known validators and attempt to validate using them
      results_by_validator = {}
      results = self.descendants.map {|c|
        validator = c.new()
        @log.debug "attempting to validate using #{validator.name}"
        result = validator.validate(challenge_password, certname, raw_csr)
        results_by_validator[validator.name] = result
        @log.debug "result: #{result.to_s}"
        result
      }
      @log.debug "validator results: " + results.to_s
      @log.info "results by validator: " + results_by_validator.to_s
      success = results.any?{|result| result == true}
      if success
        @log.info "successfully validated using one or more validators"
        return true
      else
        @log.info "unable to validate using any validator"
        return false
      end
    end

    private

    def start_logging
      @log = Logging.logger["Autosign::Validator::" + self.name.to_s]
      @log.debug "starting autosign validator: " + self.name.to_s
    end

    def perform_validation(challenge_password, certname, raw_csr)
      # override this after inheriting
      # should return true to indicate success validating
      # or false to indicate that the validator was unable to validate
      raise NotImplementedError
    end

    # perform any steps you want to take during initialization
    def setup
      true
    end

    def self.descendants
      ObjectSpace.each_object(Class).select { |klass| klass < self }
    end

    def settings
      @log.debug "merging settings"
      setting_sources = [get_override_settings, load_config, default_settings]
      merged_settings = setting_sources.inject({}) { |merged, hash| merged.deep_merge(hash) }
      @log.debug "using merged settings: " + merged_settings.to_s
      @log.debug "validating merged settings"
      if validate_settings(merged_settings)
        @log.debug "successfully validated merged settings"
        return merged_settings
      else
        @log.warn "validation of merged settings failed"
        @log.warn "unable to validate settings in #{self.name} validator"
        raise "settings validation error"
      end
    end

    # this hash will be merged with the configuration section's hash
    # override this when inheriting if you need to set config defaults
    def default_settings
      {}
    end


    # override this to perform validation checks on the merged config hash
    # of default settings, config file settings, and override settings.
    # return either true or false
    def validate_settings(settings)
      settings.is_a?(Hash)
    end

    # load any required configuration
    def load_config
      @log.debug "loading validator-specific configuration"
      config = Autosign::Config.new

      if config.settings.to_hash[self.name].nil?
        @log.warn "Unable to load validator-specific configuration"
        @log.warn "Cannot load configuration section named '#{self.name}'"
        return {}
      else
        @log.debug "Set validator-specific settings from config file: " + config.settings.to_hash[self.name].to_s
        return config.settings.to_hash[self.name]
      end
    end

    # this hook gets run to get settings from the CLI etc
    # this is how you override defaults and config file settings
    def get_override_settings
      {}
    end

  end
end

# must run at the end because the validators inherit this class
# this loads all validators
require_rel 'validators'
