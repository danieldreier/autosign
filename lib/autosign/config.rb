module Autosign
  module Exceptions
    class Validation < Exception
    end
    class NotFound < Exception
    end
    class Permissions < Exception
    end
    class Error < Exception
    end
  end
    require 'iniparse'
    require 'rbconfig'
    require 'securerandom'
    require 'deep_merge'
  class Config
    attr_accessor :location
    attr_accessor :config_file_paths
    def initialize(settings = {})
      # set up logging
      @log = Logging.logger['Autosign::Config']
      @log.debug "initializing Autosign::Config"

      # validate parameter
      raise 'settings is not a hash' unless settings.is_a?(Hash)

      # look in the following places for a config file
      @config_file_paths = ['/etc/autosign.conf', '/usr/local/etc/autosign.conf', File.join(Dir.home, '.autosign.conf')]
      @config_file_paths = [ settings['config_file'] ] unless settings['config_file'].nil?

      @settings = settings
      @log.debug "Using merged settings hash: " + @settings.to_s
    end

    def settings
      @log.debug "merging settings"
      setting_sources = [default_settings, configfile, @settings]
      setting_sources.inject({}) { |merged, hash| merged.deep_merge(hash) }
    end

    private

    def default_settings
      { 'general' =>
        {
          'loglevel'       => 'INFO',
          'token_validity' => 7200,
          'logfile'        => '/var/log/autosign.log',
          'journalfile'    => '/var/log/autosign.journal',
        },
        'jwt_token' => {
          'validity' => 7200
        }
      }
    end

    def configfile
      @log.debug "Finding config file"
      @config_file_paths.each { |file|
        @log.debug "Checking if file '#{file}' exists"
        if File.file?(file)
          @log.debug "Reading config file from: " + file
          config_file = File.read(file)
          parsed_config_file = IniParse.parse(config_file).to_hash
          @log.debug "configuration read from config file: " + parsed_config_file.to_s
          return parsed_config_file if parsed_config_file.is_a?(Hash)
        else
          @log.debug "Configuration file '#{file}' not found"
        end
      }
      return {}
    end

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

    def self.generate_default()
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
            'journalfile' => File.join(Dir.home, '/var/log/autosign.journal')
          }
        when /bsd/
          {
            'logpath'     => '/var/log/autosign.log',
            'confpath'    => '/usr/local/etc/autosign.conf',
            'journalfile' => File.join(Dir.home, '/var/log/autosign.journal')
          }
        else
          raise Autosign::Exceptions::Error, "unsupported os: #{host_os.inspect}"
        end
      )

      config = IniParse.gen do |doc|
        doc.section("general") do |general|
          general.option("loglevel", "warn")
          general.option("logfile", os_defaults['logpath'])
          general.option("journalfile", os_defaults['journalfile'])
        end
        doc.section("jwt_token") do |jwt_token|
          jwt_token.option("secret", SecureRandom.base64(15))
          jwt_token.option("validity", 7200)
        end
      end.to_ini
      raise Autosign::Exceptions::Error, "file #{os_defaults['confpath']} already exists, aborting" if File.file?(os_defaults['confpath'])
      File.write(os_defaults['confpath'], config)
    end
  end
end
