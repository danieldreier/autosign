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
  class Config
    attr_accessor :location
    def initialize(config_file = nil, settings = {})
      if config_file == nil
        @location = self.class.default_config_file ? self.class.default_config_file : :none
      else
        @location = validate_config_file(config_file) ? config_file : :none
      end

      @settings = self.default_settings.merge(self.read_configfile).merge(settings)
    end

    def self.generate_default()

      os_defaults = (
        case RbConfig::CONFIG['host_os']
        when /darwin|mac os/
          {
            'logpath'  => File.join(Dir.home, 'autosign.log'),
            'confpath' => File.join(Dir.home, '.autosign.conf'),
          }
        when /linux/
          {
            'logpath'  => '/var/log/autosign.log',
            'confpath' => '/etc/autosign.conf'
          }
        when /bsd/
          {
            'logpath'  => '/var/log/autosign.log',
            'confpath' => '/usr/local/etc/autosign.conf'
          }
        else
          raise Autosign::Exceptions::Error, "unsupported os: #{host_os.inspect}"
        end
      )

      config = IniParse.gen do |doc|
        doc.section("general",
          :comment => "general autosign tool settings"
        ) do |general|
          general.option("loglevel", "warn", :comment => "options are error, warn, info, and debug in increasing order of verbosity")
          general.option("logfile", os_defaults['logpath'], :comment => 'note that log rotation is not configured by default')
        end
        doc.section("jwt_token",
          :comment => "token-based auth settings"
        ) do |jwt_token|
          jwt_token.option("secret", SecureRandom.base64(15), :comment => "secret must be set the same on all systems using token-based auth")
          jwt_token.option("validity", 7200, :comment => "number of seconds a token will be valid for")
        end
      end.to_ini
      raise Autosign::Exceptions::Error, "file #{os_defaults['confpath']} already exists, aborting" if File.file?(os_defaults['confpath'])
      File.write(os_defaults['confpath'], config)
    end

    def settings
      @settings
    end

    def default_settings
      { 'general' =>
        {
          'loglevel'       => 'INFO',
          'token_validity' => 7200,
          'logfile'        => '/var/log/autosign.log',
        },
        'jwt_token' => {
          'validity' => 7200
        }
      }
    end

    def read_configfile(file = self.location)
      if self.location
        return IniParse.parse( File.read(self.location)).to_hash
      else
        return {}
      end
    end

    def validate_config_file(configfile = self.location)
      unless File.file?(configfile)
        STDERR.puts "configuration file not found at: #{configfile}"
        raise Autosign::Exceptions::NotFound
      end

      # check if file is world-readable
      if File.world_readable?(configfile) or File.world_writable?(configfile)
        STDERR.puts "configuration file #{configfile} is world-readable or world-writable, which is a security risk"
        raise Autosign::Exceptions::Permissions
      end

      read_configfile
    end

    def self.default_config_file_list
      ['/etc/autosign.conf', '/usr/local/etc/autosign.conf', File.join(Dir.home, '.autosign.conf')]
    end

    def self.default_config_file
      default_config_file = false
      default_locations = self.default_config_file_list

      default_locations.each do |path|
        default_config_file = path if File.file?(path)
      end
      if default_config_file.is_a?(String)
        return default_config_file
      else
        STDERR.puts "unable to locate configuration file in #{default_locations.join(', ')}"
        return default_config_file
      end
    end

  end
end
