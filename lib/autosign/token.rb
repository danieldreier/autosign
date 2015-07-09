module Autosign
  require 'jwt'
  require 'JSON'
  require 'securerandom'

  class Token
    attr_reader :validfor
    attr_reader :certname
    attr_reader :reusable
    attr_reader :requester
    attr_reader :secret
    attr_reader :validto
    attr_reader :uuid

    def initialize(certname, reusable=false, validfor=7200, requester, secret)
      @validfor  = validfor
      @certname  = certname
      @reusable  = reusable
      @requester = requester
      @secret    = secret
      @uuid      = SecureRandom.uuid # UUID is needed to allow token regeneration with the same settings
      @validto   = Time.now.to_i + self.validfor
      self.create(validfor, secret)
    end

    def self.validate(requested_certname, token, hmac_secret)
      errors = []
      begin
        data = JSON.parse(JWT.decode(token, hmac_secret)[0]["data"])
      rescue JWT::ExpiredSignature
        errors << "Expired Signature"
      rescue
        errors << "Invalid Token"
      end
      return "validation failed with: #{errors.join(', ')}" unless errors.count == 0
      certname_is_regex = (data["certname"] =~ /\/[^\/].*\//) ? true : false

      if certname_is_regex
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
        puts "validation failed with: #{errors.join(', ')}"
        return false
      else
        return true
      end

      # we should never get here, but if we do we should break instead of returning anything
      raise Autosign::Token::ValidationError
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
      validto   = Time.now.to_i + validfor

      self.new(certname, reusable, validfor, requester, hmac_secret)
    end

    def validfor=(str)
      @validfor = str
    end

    def validto()
      @validto = Time.now.to_i + self.validfor
    end

    def certname=(str)
      @name = str
    end

    def reusable=(str)
      @reusable
    end

    def requester=(str)
      @requester
    end

    def secret=(str)
      @secret
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

    def create(validfor, secret)
#      self.sign(self.to_hash, validfor, secret)
    end

    def sign()
      exp_payload = { :data => self.to_json, :exp => self.validto.to_s}
      JWT.encode exp_payload, self.secret, 'HS512'
    end

  end
end
