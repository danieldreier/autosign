require 'rbconfig'
require 'securerandom'
require 'deep_merge'
require 'yaml'

module Autosign
  # Exceptions namespace for Autosign class
  module Exceptions
    # Exception representing a general failure during validation
    class Validation < Exception
    end
    # Exception representing a missing file during config validation
    class NotFound < Exception
    end
    # Exception representing a permissions error during config validation
    class Permissions < Exception
    end
    # Exception representing errors that Autosign does not know how to handle
    class Error < Exception
    end
  end

  # Class to manage configuration settings.
  # The purpose of this class is to interact with the configuration file,
  # merge defaults and user-provided settings, and present a configuration hash
  # so that validators and other components do not have to re-implement config
  # file handling.
  class Config
    # Create a config instance to interact with configuration settings
    # To specify a configuration file, settings_param should include something like:
    # {'config_file' => '/usr/local/etc/autosign.conf'}
    #
    # If no defaults are provided, the class checks several common locations for config file path.
    #
    # @param settings_param [Hash] config settings that should override defaults and config file settings
    # @return [Autosign::Config] instance of the Autosign::Config class
    def initialize(settings_param = {})
      # set up logging
      @log = Logging.logger[self.class]
      @log.debug "initializing #{self.class.name}"
      # validate parameter
      raise 'settings is not a hash' unless settings_param.is_a?(Hash)

      # look in the following places for a config file
      @config_file_paths = ['/etc/autosign.conf', '/usr/local/etc/autosign.conf']

      # HOME is unset when puppet runs, so we need to only use it if it's set
      @config_file_paths << File.join(Dir.home, '.autosign.conf') unless ENV['HOME'].nil?
      @config_file_paths = [ settings_param['config_file'] ] unless settings_param['config_file'].nil?

      @settings = settings_param
      @log.debug "Using merged settings hash: " + @settings.to_s
    end

    # Return a merged settings hash of defaults, config file settings
    # and passed in settings (such as from the CLI)
    #
    # @return [Hash] deep merged settings hash
    def settings
      @log.debug "merging settings"
      setting_sources = [default_settings, configfile, @settings]
      merged_settings = setting_sources.inject({}) { |merged, hash| merged.deep_merge!(hash) }
      @log.debug "using merged settings: " + merged_settings.to_s
      return merged_settings
    end

    private

    # default settings hash for the whole autosign gem
    # the format must map to something an ini file can represent, so the
    # structure should have a top-level key named "general" and key-value pairs
    # below it, with strings as keys and strings or integers as values.
    #
    # validator settings should not be here; put those in the validator's
    # default settings method.
    #
    # @return [Hash] default configuration settings
    def default_settings
      { 'general' =>
        {
          'loglevel'       => 'INFO',
        },
        'jwt_token' => {
          'validity' => 7200
        }
      }
    end

    # Locate the configuration file, parse it from INI-format, and return
    # the results as a hash. Returns an empty hash if no config file is found.
    #
    # @return [Hash] configuration settings loaded from INI file
    def configfile
      @log.debug "Finding config file"
      @config_file_paths.each { |file|
        @log.debug "Checking if file '#{file}' exists"
        if File.file?(file)
          @log.debug "Reading config file from: " + file
          config_file = File.read(file)
          parsed_config_file = YAML.load(config_file)
          #parsed_config_file = IniParse.parse(config_file).to_hash
          @log.debug "configuration read from config file: " + parsed_config_file.to_s
          return parsed_config_file if parsed_config_file.is_a?(Hash)
        else
          @log.debug "Configuration file '#{file}' not found"
        end
      }
      return {}
    end

    # Validate configuration file
    # Raises an exception if the config file cannot be validated
    #
    # @param configfile [String] the absolute path of the config file to validate
    # @return [String] the absolute path of the config file
    def validate_config_file(configfile = location)
      @log.debug "validating config file"
      unless File.file?(configfile)
        @log.error "configuration file not found at: #{configfile}"
        raise Autosign::Exceptions::NotFound
      end

      # check if file is world-readable
      if File.world_readable?(configfile) or File.world_writable?(configfile)
        @log.error "configuration file #{configfile} is world-readable or world-writable, which is a security risk"
        raise Autosign::Exceptions::Permissions
      end

      configfile
    end

    # Generate a default configuration file
    # As a convenience for the user, we can generate a default config file
    # This class is currently too tightly coupled with the JWT token validator
    def self.generate_default(settings_param = {})
      os_defaults = (
        case RbConfig::CONFIG['host_os']
        when /darwin|mac os/
          {
            'logpath'     => File.join(Dir.home, 'autosign.log'),
            'confpath'    => File.join(Dir.home, '.autosign.conf'),
            'journalfile' => File.join(Dir.home, '.autosign.journal')
          }
        when /linux/
          {
            'logpath'     => '/var/log/autosign.log',
            'confpath'    => '/etc/autosign.conf',
            'journalfile' => File.join(Dir.home, '/var/autosign/autosign.journal')
          }
        when /bsd/
          {
            'logpath'     => '/var/log/autosign.log',
            'confpath'    => '/usr/local/etc/autosign.conf',
            'journalfile' => File.join(Dir.home, '/var/autosign/autosign.journal')
          }
        else
          raise Autosign::Exceptions::Error, "unsupported os: #{host_os.inspect}"
        end
      )

      config = {
        'general' => {
          'loglevel' => 'warn',
          'logfile' =>  os_defaults['logpath']
        },
        'jwt_token' => {
          'secret' =>  SecureRandom.base64(20),
          'validity' => '7200',
          'journalfile' => os_defaults['journalfile']
        }
      }

#      config = IniParse.gen do |doc|
#        doc.section("general") do |general|
#          general.option("loglevel", "warn")
#          general.option("logfile", os_defaults['logpath'])
#        end
#        doc.section("jwt_token") do |jwt_token|
#          jwt_token.option("secret", SecureRandom.base64(15))
#          jwt_token.option("validity", 7200)
#          jwt_token.option("journalfile", os_defaults['journalfile'])
#        end
#        doc.section("multiplexer") do |jwt_token|
#          jwt_token.option(";external_policy_executable", '/usr/local/bin/some_autosign_executable')
#          jwt_token.option(";external_policy_executable", '/usr/local/bin/another_autosign_executable')
#        end
#        doc.section("password_list") do |jwt_token|
#          jwt_token.option(";password", 'static_autosign_password_here')
#          jwt_token.option(";password", 'another_static_autosign_password')
#        end
#      end.to_ini
      config_file=settings_param['config_file'] || os_defaults['confpath']
      raise Autosign::Exceptions::Error, "file #{config_file} already exists, aborting" if File.file?(config_file)
      return config_file if File.write(config_file, config.to_yaml)
    end
  end
end
