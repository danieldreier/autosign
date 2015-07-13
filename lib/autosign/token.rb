module Autosign
  require 'jwt'
  require 'json'
  require 'securerandom'

  class Token
    attr_reader :validfor
    attr_reader :certname
    attr_reader :reusable
    attr_reader :requester
    attr_reader :secret
    attr_accessor :validto
    attr_accessor :uuid

    def initialize(certname, reusable=false, validfor=7200, requester, secret)
      # set up logging
      @log = Logging.logger['Autosign::Token']
      @log.debug "initializing"

      @validfor  = validfor
      @certname  = certname
      @reusable  = reusable
      @requester = requester
      @secret    = secret
      @uuid      = SecureRandom.uuid # UUID is needed to allow token regeneration with the same settings
      @validto   = Time.now.to_i + self.validfor
    end

    def self.validate(requested_certname, token, hmac_secret)
      @log = Logging.logger['Autosign::Token.validate']
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

    def self.from_token(token, hmac_secret)
      begin
        decoded = JWT.decode(token, hmac_secret)[0]
      rescue JWT::ExpiredSignature
        raise Autosign::Token::ExpiredToken
      rescue
        raise Autosign::Token::Invalid
      end
      certname  = JSON.parse(decoded["data"])["certname"]
      requester = JSON.parse(decoded["data"])["requester"]
      reusable  = JSON.parse(decoded["data"])["reusable"]
      validfor  = JSON.parse(decoded["data"])["validfor"]

      new_token = self.new(certname, reusable, validfor, requester, hmac_secret)
      new_token.validto = self.token_validto(token, hmac_secret)
      new_token.uuid = JSON.parse(decoded["data"])["uuid"]

      return new_token
    end

    def certname=(str)
      @name = str
    end

    def reusable=(bool)
      @reusable = !!bool
    end

    def reusable
      !!@reusable
    end

    def requester=(str)
      @requester = str
    end

    def secret=(str)
      @secret = str
    end

    def to_hash
      {
        "certname"  => self.certname,
        "requester" => self.requester,
        "reusable"  => self.reusable,
        "validfor"  => self.validfor,
        "uuid"      => self.uuid
      }
    end

    def to_json
      JSON.generate self.to_hash
    end

    def sign()
      exp_payload = { :data => self.to_json, :exp => self.validto.to_s}
      JWT.encode exp_payload, self.secret, 'HS512'
    end

  end
end
