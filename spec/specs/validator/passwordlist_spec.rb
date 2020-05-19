require 'spec_helper'
require 'securerandom'
require 'autosign/validator/passwordlist'
context Autosign::Validator::Passwordlist do
  let(:certname)  { 'host.example.com' }
  let(:validator) { Autosign::Validator::Passwordlist.new }

  before {
    # stub configuration
    data = { 'general' => {
               'loglevel' => :debug,
               'logfile'  => '/tmp/autosign.log'
               },
             'password_list' => {
                'password' => ['hunter2', 'opensesame', 'CPE1704TKS']
               }
             }
    allow_any_instance_of(Autosign::Config).to receive(:settings).and_return(data)
  }

  context 'class methods' do
    describe '.new' do
      it 'requires no parameters' do
        expect { Autosign::Validator::Passwordlist.new }.to_not raise_error
      end
    end
  end

  context 'instance methods' do
    describe '.name' do
      it 'returns a string' do
        expect(validator.name).to be_a(String)
      end
      it 'returns the string "password_list"' do
        expect(validator.name).to eq('password_list')
      end
    end
    describe '.validate' do
      it 'validates a request with a valid password' do
        expect(validator.validate('hunter2', 'foo.example.com', 'dummy_csr_data')).to be true
        expect(validator.validate('opensesame', 'foo.example.com', 'dummy_csr_data')).to be true
        expect(validator.validate('CPE1704TKS', 'foo.example.com', 'dummy_csr_data')).to be true
      end
      it 'does not validate a request with an invalid password' do
        expect(validator.validate('bad_password', 'foo.example.com', 'dummy_csr_data')).to be false
        expect(validator.validate('', 'foo.example.com', 'dummy_csr_data')).to be false
      end
    end

  end
end
