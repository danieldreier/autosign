# frozen_string_literal: true

module Autosign
  module Validators
    # Validate certificate signing requests using a simple password list.
    # This is not a very secure or flexible validation scheme, but is provided
    # because so many existing autosign policy scripts implement it.
    #
    # @example validate CSRs when the challengePassword OID is set to any of "hunter2", "opensesame", or "CPE1704TKS"
    #   # In /etc/autosign.conf, include the following configuration:
    #   [password_list]
    #   password = hunter2
    #   password = opensesame
    #   password = CPE1704TKS
    #
    class Passwordlist < Autosign::Validator
      NAME = 'password_list'

      private

      def perform_validation(password, _certname, _raw_csr)
        @log.debug 'validating against simple password list'
        @log.debug 'passwords: ' + settings.to_s
        result = validate_password(password.to_s)
        @log.debug 'validation result: ' + result.to_s
        result
      end

      def validate_password(password)
        @log.debug 'Checking if password list includes password'
        password_list.include?(password.to_s)
      end

      def password_list
        Array(settings['password'])
      end

      def validate_settings(settings)
        @log.debug 'validating settings: ' + settings.to_s
        true
      end
    end
  end
end
