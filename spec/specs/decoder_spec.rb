require 'spec_helper'

context Autosign::Decoder do
  describe '.decode_csr' do
    let(:csr) { File.read(File.join('fixtures', 'i-7672fe81.pem')) }

    it 'Accepts a CSR as the parameter' do
      expect { Autosign::Decoder.decode_csr(csr) }.to_not raise_error
    end

    it 'Extracts the challenge_password and common_name from a CSR' do
      expect(Autosign::Decoder.decode_csr(csr)).to eq({:challenge_password=>"eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJkYXRhIjoie1wiY2VydG5hbWVcIjpcImktNzY3MmZlODFcIixcInJlcXVlc3RlclwiOlwiRGFuaWVscy1NYWNCb29rLVByby0yLmxvY2FsXCIsXCJyZXVzYWJsZVwiOmZhbHNlLFwidmFsaWRmb3JcIjoxNTc2ODAwMDAsXCJ1dWlkXCI6XCJlMzZkMzkyOS05NWVlLTQyNDQtOTIwZS00NmZiN2Y4MTU3ZDVcIn0iLCJleHAiOiIxNTk1MTc3NTc0In0.gfTpUPLGnxwtvfMH5C0ucWsXBqrhBD_HvCiNH_9zvhFafHMij_ng14K8F-MMLgQoDBloOJukjX8qcki5cFmKKg", :common_name=>"i-7672fe81"})
    end

    it 'Returns nil given an invalid CSR' do
      expect(Autosign::Decoder.decode_csr("not_a_csr")).to be_nil
    end

    it 'Does not raise an error decoding a CSR without a challengePassword' do
      allow_any_instance_of(OpenSSL::X509::Attribute).to receive(:oid).and_return('notTheOidYouAreLookingFor')
      expect { Autosign::Decoder.decode_csr(csr) }.to_not raise_error
    end
  end
end
