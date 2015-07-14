require 'spec_helper'

context Autosign::Decoder do
  describe '.decode_csr' do
    let(:csr) { File.read(File.join('fixtures', 'i-7672fe81.pem')) }
    it 'Accepts a CSR as the parameter' do
      expect { Autosign::Decoder.decode_csr(csr) }.to_not raise_error
    end
    it 'Extracts the challenge_password and common_name from a CSR' do
      expect(Autosign::Decoder.decode_csr(csr)).to eq({:challenge_password=>"eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJkYXRhIjoie1wiY2VydG5hbWVcIjpcImktNzY3MmZlODFcIixcInJlcXVlc3RlclwiOlwiRGFuaWVscy1NYWNCb29rLVByby0yLmxvY2FsXCIsXCJyZXVzYWJsZVwiOmZhbHNlLFwidmFsaWRmb3JcIjo5OTk5OTksXCJ1dWlkXCI6XCI0YTM2ZjA0NS1jNmNlLTRiZjYtYmEzYy02ZjNlNzhlNmI3MWNcIn0iLCJleHAiOiIxNDM3NDcwMTk2In0.OZQdenVzIxy-Is271TK0qqhKmRfqkB2Lhscsz-kIK4HQaem3Awx7zVkiCpj0_eFckgaKYNBMAdhUfIMqS3IMmw", :common_name=>"i-7672fe81"})
    end
    it 'Returns nil given an invalid CSR' do
      expect(Autosign::Decoder.decode_csr("not_a_csr")).to be_nil
    end
  end
end
