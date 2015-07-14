require 'spec_helper'
require 'securerandom'

context Autosign::Token do
  let(:certname)  { 'host.example.com' }
  let(:reusable)  { false }
  let(:validfor)  { rand(60..604800) }
  let(:requester) { 'Autosign::Token rspec_test' }
  let(:secret)    { 'very_secret' }
  let(:token)     { Autosign::Token.new(certname, reusable, validfor, requester, secret) }
  let(:reusable_token)     { Autosign::Token.new(certname, true, validfor, requester, secret) }
  let(:signed_token)     { token.sign }
  let(:wildcard_signed_token)     { Autosign::Token.new('/.*\.example\.com/', reusable, validfor, requester, secret).sign }
  let(:expired_token)     { Autosign::Token.new(certname, reusable, -1, requester, secret).sign }
  let(:reconstituted_token) { Autosign::Token.from_token(signed_token, secret) }


  context 'class methods' do
    describe '.new' do
      it 'accepts expected parameters' do
        expect { Autosign::Token.new(certname, reusable, validfor, requester, secret) }.to_not raise_error
      end
    end
    describe '.validate' do
      it 'validates a previously-generated token' do
        expect(Autosign::Token.validate(certname, signed_token, secret)).to be true
      end
      it 'validates a previously-generated wildcard token' do
        expect(Autosign::Token.validate(certname, wildcard_signed_token, secret)).to be true
      end
      it 'does not validate a previously-generated wildcard token when it does not match the hostname' do
        expect(Autosign::Token.validate('not_the_regex', wildcard_signed_token, secret)).to be false
      end
      it 'does not validate a token when the secret does not match' do
        expect(Autosign::Token.validate(certname, signed_token, 'wrong_secret')).to be false
      end
      it 'does not validate a token when the certname does not match' do
        expect(Autosign::Token.validate('wrong' + certname, signed_token, secret)).to be false
      end
      it 'does not validate an expired token' do
        expect(Autosign::Token.validate(certname, expired_token, secret)).to be false
      end
    end
    describe '.from_token' do
      it 'returns an Autosign::Token instance' do
        expect(Autosign::Token.from_token(signed_token, secret)).to be_a(Autosign::Token)
      end
      it 'has the same hash values as the original token' do
        expect(reconstituted_token.to_hash).to eq(token.to_hash)
      end
    end
    describe '.token_validto' do
      it 'returns an integer' do
        expect(Autosign::Token.token_validto(signed_token, secret)).to be_an(Integer)
      end
      it 'returns valid POSIX time' do
        expect(Time.at(Autosign::Token.token_validto(signed_token, secret))).to be_a(Time)
      end
      it 'returns time reasonable close to the current time' do
        expect(Time.at(Autosign::Token.token_validto(signed_token, secret)).between?(Time.now, Time.now + 604801)).to be true
      end
    end
  end

  context 'instance methods' do
    describe '.validto' do
      it 'returns an integer' do
        expect(token.validfor).to be_a(Integer)
      end
      it 'Returns validto time' do
        expect(token.validfor).to eq(validfor)
      end
    end
    describe '.reusable' do
      it 'returns the expected value' do
        expect(token.reusable).to be(reusable)
        expect(reusable_token.reusable).to be true
      end
    end
    describe '.to_hash' do
      it 'returns a hash' do
        expect(token.to_hash).to be_a(Hash)
      end
      it 'includes the expected certname, requester, reusable, validfor, and a uuid' do
        expect(token.to_hash).to include(
          "certname"  => eq(certname),
          "requester" => eq(requester),
          "reusable"  => eq(reusable),
          "validfor"  => eq(validfor),
          "uuid"      => be_a(String)
        )
      end
    end
    describe '.sign' do
      it 'returns a string' do
        expect(token.sign).to be_a(String)
      end
    end


  end
end
