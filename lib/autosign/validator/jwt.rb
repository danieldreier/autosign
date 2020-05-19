# frozen_string_literal: true
require 'autosign/validator/validator_base'

module Autosign
  module Validator
    # Validate certificate signing requests using JSON Web Tokens (JWT).
    # This is the expected primary validator when using the autosign gem.
    # Validation requires that the shared secret used to generate the JWT is
    # the same as on the validating system. The validator also checks that the
    # token has not expired, and that one-time (non-reusable) tokens have not
    # been previously used.
    class JWT < Autosign::Validator::ValidatorBase
      NAME = 'jwt_token'

      private

      # Validate a JWT token.
      # Validation relies on the Autosign::Token class, then additionally
      # confirms that one-time tokens have not already been used by adding them
      # to the journal.
      # @param token [String] Base64 encoded JSON web token
      # @param certname [String] the certname being requested in the certificate signing request
      # @param raw_csr [String] Raw CSR; not used in this validator.
      # @return [True, False] returns true to indicate successful validation, and false to indicate failure to validate
      def perform_validation(token, certname, _raw_csr)
        @log.info "attempting to validate with #{name}"
        unless Autosign::Token.validate(certname, token, settings['secret'])
          return false
        end

        @log.info 'validated JWT token'
        @log.debug 'validated JWT token, checking reusability'

        return true if is_reusable?(token)
        return true if add_to_journal(token)

        false
      end

      def is_reusable?(token)
        Autosign::Token.from_token(token, settings['secret']).reusable?
      end

      # Attempt to add a token to the one-time token journal.
      # The journal lists previously used non-reusable tokens, indexed by UUID.
      #
      # @param token [String] Base64 encoded JSON web token
      # @return [True, False] returns true if the token was successfully added to the journal, or false if the token was previously used and is already in the journal
      def add_to_journal(token)
        validated_token = Autosign::Token.from_token(token, settings['secret'])
        @log.debug 'add_to_journal settings: ' + settings.to_s
        journal = Autosign::Journal.new('journalfile' => settings['journalfile'])
        token_expiration = Autosign::Token.token_validto(token, settings['secret'])

        # adding will return false if the token is already in the journal
        if journal.add(validated_token.uuid, token_expiration, validated_token.to_hash)
          @log.info "added token with UUID '#{validated_token.uuid}' to journal"
          true
        else
          @log.warn 'journal cannot validate one-time token; may already have been used'
          false
        end
      end

      def default_settings
        {
          'journalfile' => '/var/autosign/autosign.journal'
        }
      end

      # Override some configuration settings using environment variables to
      # simplify testing. This is a hack to make testing easier.
      # Cucumber sets environment variables because it's easier than templating
      # out config files.
      #
      # This should probably be done differently at some point.
      def get_override_settings
        if (ENV['AUTOSIGN_TESTMODE'] == 'true') &&
           !ENV['AUTOSIGN_TEST_SECRET'].nil? &&
           !ENV['AUTOSIGN_TEST_JOURNALFILE'].nil?
          {
            'secret' => ENV['AUTOSIGN_TEST_SECRET'].to_s,
            'journalfile' => ENV['AUTOSIGN_TEST_JOURNALFILE'].to_s
          }
        else
          {}
        end
      end

      # Validate that the settings hash contains a secret.
      # The validator cannot function without a secret, so there's no point
      # in continuing to run if it was configured without a secret.
      # @param settings [Hash] settings hash
      # @return [True, False] return true if settings are valid, false if config is unusable
      def validate_settings(settings)
        @log.debug 'validating settings: ' + settings.to_s
        if settings['secret'].is_a?(String)
          @log.info "validated settings successfully for #{name}"
          true
        else
          @log.error 'no secret setting found'
          false
        end
      end
    end
  end
end
