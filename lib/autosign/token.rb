module Autosign
  require 'jwt'
  require 'json'
  require 'securerandom'

  # Class modeling JSON Web Tokens as credentials for certificate auto signing.
  # See http://jwt.io for more information about JSON web tokens in general.
  #
  # @return [Autosign::Token] instance of the Autosign::Token class
  class Token
    # @return [Integer, String] seconds that the token will be valid for after being issued
    attr_reader :validfor
    # @return [String] common name or regex of common names for which this token is valid
    attr_reader :certname
    # @return [True, False] true if the token can be used multiple times, false if the token is intended as a one-time credential
    attr_reader :reusable
    # @return [String] arbitrary string identifying the person or machine that generated the token initially
    attr_reader :requester
    # @return [String] shared HMAC secret used to sign or validate tokens
    attr_reader :secret
    # @return [Integer, String] POSIX seconds since epoch that the token is valid until
    attr_accessor :validto
    # @return [String] RFC4122 v4 UUID functioning as unique identifier for the token
    attr_accessor :uuid

    # Create a token instance to model an individual JWT token
    #
    # @param certname [String] common name or regex of common names for which this token is valid
    # @param reusable [True, False] true if the token can be used multiple times, false if the token is intended as a one-time credential
    # @param validfor [Integer, String] seconds that the token will be valid for, starting at the current time
    # @param requester [String] arbitrary string identifying the person or machine that generated the token initially
    # @param secret [String] shared HMAC secret used to sign or validate tokens
    # @return [Autosign::Config] instance of the Autosign::Config class
    def initialize(certname, reusable=false, validfor=7200, requester, secret)
      # set up logging
      @log = Logging.logger[self.class]
      @log.debug "initializing #{self.class.name}"

      @validfor  = validfor
      @certname  = certname
      @reusable  = reusable
      @requester = requester
      @secret    = secret
      @uuid      = SecureRandom.uuid # UUID is needed to allow token regeneration with the same settings
      @validto   = Time.now.to_i + self.validfor
    end

    # Validate an existing JSON Web Token.
    #
    # 1. Use the HMAC secret to validate the data in the token
    # 2. Compare the expiration time in the token to the current time to determine if it's valid
    # 3. compare the certname or regex of certnames in the token to the requested common name from the certificate signing request
    #
    # @param requested_certname [String] common name coming from the certificate signing request. This is the common name the requester wants.
    # @param token [String] JSON Web Token coming from the certificate signing request
    # @param hmac_secret [String] Password that the token was (hopefully) originally signed with.
    # @return [True, False] returns true if the token can be validated, or false if the token cannot be validated.
    def self.validate(requested_certname, token, hmac_secret)
      @log = Logging.logger[self.class]
      @log.debug "attempting to validate token"
      @log.info "attempting to validate token for: #{requested_certname.to_s}"
      errors = []
      begin
        @log.debug "Decoding and parsing token"
        data = JSON.parse(JWT.decode(token, hmac_secret)[0]["data"])
      rescue JWT::ExpiredSignature
        @log.warn "Token has an expired signature"
        errors << "Expired Signature"
      rescue
        @log.warn "Unable to validate token successfully"
        errors << "Invalid Token"
      end
      @log.warn "validation failed with: #{errors.join(', ')}" unless errors.count == 0

      if data.nil?
        @log.error "token is nil; this probably means the token failed to validate"
        return false
      end

      certname_is_regex = (data["certname"] =~ /\/[^\/].*\//) ? true : false

      if certname_is_regex
        @log.debug "validating certname as regular expression"
        regexp = Regexp.new(/\/([^\/].*)\//.match(data["certname"])[1])
        unless regexp.match(requested_certname)
          errors << "certname: '#{requested_certname}' does not match validation regex: '#{regexp.to_s}'"
        end
      else
        unless data["certname"] == requested_certname
          errors << "certname: '#{requested_certname}' does not match certname '#{data["certname"]}' in token"
        end
      end

      unless errors.count == 0
        @log.warn "validation failed with: #{errors.join(', ')}"
        return false
      else
        @log.info "validated token successfully"
        return true
      end

      # we should never get here, but if we do we should break instead of returning anything
      @log.error "unexpectedly reached end of validation method"
      raise Autosign::Token::ValidationError
    end

    # check if the token is reusable or a one-time use token
    # @return [True, False] return true if the token can be used multiple times, false if the token can only be used once
    def reusable?
      !!@reusable
    end

    # convert the token to a hash
    # @return [Hash{String => String}]
    def to_hash
      {
        "certname"  => certname,
        "requester" => requester,
        "reusable"  => reusable?,
        "validfor"  => validfor,
        "uuid"      => uuid
      }
    end

    # Sign the token with HMAC using a SHA-512 hash
    def sign()
      exp_payload = { :data => to_json, :exp => validto.to_s}
      JWT.encode exp_payload, secret, 'HS512'
    end

    # Create an Autosign::Token object from a serialized token after validating
    # the signature and expiration time validity.
    #
    # @param token [String] JSON Web Token coming from the certificate signing request
    # @param secret [String] shared HMAC secret used to sign or validate tokens
    # @return [Autosign::Token] instance of Autosign::Token with the settings from the serialized token
    def self.from_token(token, hmac_secret)
      begin
        decoded = JWT.decode(token, hmac_secret)[0]
      rescue JWT::ExpiredSignature
        raise Autosign::Token::ExpiredToken
      rescue
        raise Autosign::Token::Invalid
      end
      cert_data = JSON.parse(decoded["data"])
      new_token = self.new(cert_data["certname"], cert_data["reusable"], cert_data["validfor"],
                           cert_data["requester"], hmac_secret)

      new_token.validto = self.token_validto(token, hmac_secret)
      new_token.uuid = cert_data["uuid"]

      new_token
    end

    # Extract the expiration time, in seconds since epoch, from a signed token. Uses HMAC secret to validate the expiration time.
    # @param token [String] Serialized JSON web token
    # @param hmac_secret [String] Password that the token was (hopefully) originally signed with.
    # @return [Integer] POSIX time (seconds since epoch) that the token is valid until
    def self.token_validto(token, hmac_secret)
      begin
        decoded = JWT.decode(token, hmac_secret)[0]
      rescue JWT::ExpiredSignature
        raise Autosign::Token::ExpiredToken
      rescue
        raise Autosign::Token::Invalid
      end
      return decoded['exp'].to_i
    end

    private

    def certname=(str)
      @name = str
    end

    def reusable=(bool)
      @reusable = !!bool
    end

    def requester=(str)
      @requester = str
    end

    def secret=(str)
      @secret = str
    end

    def to_json
      JSON.generate to_hash
    end

  end
end
