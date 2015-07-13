module Autosign
  module Validators
    class Multiplexer < Autosign::Validator
      def name
        "multiplexer"
      end

      private

      def perform_validation(token, certname, raw_csr)
        results = []
        @log.debug "validating using multiplexed external executables"
        policy_executables.each {|executable|
          @log.debug "attempting to validate using #{executable.to_s}"
          results << IO.popen(executable, 'r+') {|obj| obj.puts raw_csr; obj.close_write; obj.read; obj.close; $?.to_i }
          @log.debug "exit code from #{executable.to_s}: #{results.last}"
        }
        bool_results = results.map {|val| val == 0}
        return validate_using_strategy(bool_results)
      end


      def default_settings
        {
          'strategy' => 'any',
        }
      end

    def validate_using_strategy(array)
      case settings['strategy']
      when 'any'
        @log.debug "validating using 'any' strategy"
        return array.any?
      when 'all'
        @log.debug "validating using 'all' strategy"
        return array.all?
      else
        @log.error "unable to validate; unknown strategy"
        return false
      end
    end

    def policy_executables
      @log.debug "in policy_executables"
      return [] if settings['external_policy_executables'].nil?
      settings['external_policy_executables'].split(',').map{ |s| s.strip }
    end


    def validate_settings(settings)
      @log.debug "validating settings: " + settings.to_s
      unless ['any', 'all'].include? settings['strategy']
        @log.error "strategy setting must be set to 'any' or 'all'"
        return false
      end

      unless settings['external_policy_executables'].nil?
        @log.debug "validating that external_policy_executables list is a string"
        return false unless settings['external_policy_executables'].is_a?(String)
        @log.debug "validating that external_policy_executables list is a comma separated list"
        external_policy_executables = settings['external_policy_executables'].split(',').map{ |s| s.strip }
        return false unless external_policy_executables.is_a?(Array)

        external_policy_executables.each {|path|
          @log.debug "validating that #{path} is executable"
          return false unless File.executable?(path)
        }
      end
      @log.debug "done validating settings"
      true
    end

    end
  end
end
