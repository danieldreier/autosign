module Autosign
  class Decoder
    # Extract common name and challenge_password OID from X509 SSL Certificate signing requests
    #
    # @param csr[String] X509 format CSR
    # @return [Hash] hash containing :challenge_password and :common_name keys
    def self.decode_csr(csr)
      @log = Logging.logger['Autosign::Decoder']
      @log.debug "decoding CSR"

      begin
        csr = OpenSSL::X509::Request.new(csr)
      rescue OpenSSL::X509::RequestError
        @log.error "Rescued OpenSSL::X509::RequestError; unable to decode CSR"
        return nil
      end

      # extract challenge password
      challenge_password = csr.attributes.select { |a| a.oid == 'challengePassword' }.first.value.value.first.value

      # extract common name
      common_name = /^\/CN=(\S*)$/.match(csr.subject.to_s)[1]

      output = {
        :challenge_password => challenge_password,
        :common_name        => common_name
      }

      @log.info "Decoded CSR for CN: " + output[:common_name].to_s
      @log.debug "Decoded CSR as: " + output.to_s
      return output
    end
  end
end
