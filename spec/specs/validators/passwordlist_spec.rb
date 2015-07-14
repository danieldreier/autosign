require 'spec_helper'
require 'securerandom'

context Autosign::Validators::Passwordlist do
  let(:certname)  { 'host.example.com' }
  let(:validator) { Autosign::Validators::Passwordlist.new }

  # this is a crude way to fake the config file
  before {
    data = '[password_list]
password = hunter2
password = opensesame
password = CPE1704TKS'
    allow(File).to receive(:read).and_return(data)
  }

  context 'class methods' do
    describe '.new' do
      it 'requires no parameters' do
        expect { Autosign::Validators::Passwordlist.new() }.to_not raise_error
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
