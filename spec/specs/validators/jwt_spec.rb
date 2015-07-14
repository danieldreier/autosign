require 'spec_helper'
require 'securerandom'

context Autosign::Validators::JWT do
  let(:certname)  { 'host.example.com' }
  let(:validator) { Autosign::Validators::JWT.new }

  let(:one_time_token) { Autosign::Token.new('foo.example.com', false, 3600, 'rspec_test', 'secret').sign }
  let(:reusable_token) { Autosign::Token.new('foo.example.com',  true, 3600, 'rspec_test', 'secret').sign }
  let(:expired_token)  { Autosign::Token.new('foo.example.com',  true,   -1, 'rspec_test', 'secret').sign }

  context 'class methods' do
    describe '.new' do
      it 'requires no parameters' do
        expect { Autosign::Validators::JWT.new() }.to_not raise_error
      end
    end
  end

  context 'instance methods' do
    describe '.name' do
      it 'returns a string' do
        expect(validator.name).to be_a(String)
      end
      it 'returns the string "jwt_token"' do
        expect(validator.name).to eq('jwt_token')
      end
    end
    describe '.validate' do
      it 'validates a JWT token' do
        expect(validator.validate(one_time_token, 'foo.example.com', 'dummy_csr_data')).to be true
      end
      it 'does not validate a token with the wrong hostname' do
        expect(validator.validate(one_time_token, 'wrong.example.com', 'dummy_csr_data')).to be false
      end
      it 'does not validate an expired token' do
        expect(validator.validate(expired_token, 'foo.example.com', 'dummy_csr_data')).to be false
      end
      it 'does not validate an invalid token' do
        expect(validator.validate(SecureRandom.urlsafe_base64(200), 'foo.example.com', 'dummy_csr_data')).to be false
      end
      it 'does not validate a re-used one-time token' do
        expect(validator.validate(one_time_token, 'foo.example.com', 'dummy_csr_data')).to be true
        expect(validator.validate(one_time_token, 'foo.example.com', 'dummy_csr_data')).to be false
      end
      it 'does validate a re-used re-usable token' do
        expect(validator.validate(reusable_token, 'foo.example.com', 'dummy_csr_data')).to be true
        expect(validator.validate(reusable_token, 'foo.example.com', 'dummy_csr_data')).to be true
      end
    end

  end
end
