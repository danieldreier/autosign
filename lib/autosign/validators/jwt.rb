module Autosign
  module Validators
    class JWT < Autosign::Validator
      def name
        "jwt_token"
      end

      private

      def perform_validation(challenge_password, certname)
        Autosign::Token.validate(certname, challenge_password, settings['secret'])
      end

      def default_settings
        {}
      end

      def get_override_settings
        {}
      end

    def validate_settings(settings)
      @log.debug "validating settings: " + settings.to_s
      if settings['secret'].is_a?(String)
        @log.info "validated settings successfully"
        return true
      else
        @log.error "no secret setting found"
        return false
      end
    end

    end
  end
end
