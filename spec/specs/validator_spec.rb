# frozen_string_literal: true

require 'spec_helper'
require 'securerandom'

describe Autosign::Validator do

  let(:config_obj) { Autosign::Config.new(settings) }
  let(:settings) do
    {'config_file' => File.join(fixtures_dir, 'settings_file.yaml') }
  end

  let(:certname) { 'foo.example.com' }
  let(:one_time_token) { Autosign::Token.new(certname, false, 3600, 'rspec_test', 'secret').sign }
  let(:reusable_token) { Autosign::Token.new(certname,  true, 3600, 'rspec_test', 'secret').sign }
  let(:expired_token)  { Autosign::Token.new(certname,  true, -1, 'rspec_test', 'secret').sign }
  let(:validation_order) do
    %w[
      jwt_token multiplexer password_list
    ]
  end
  let(:csr) do
    generate_csr(
      common_name: certname,
      organization: 'ACME Corp.',
      country: 'US',
      state_name: 'California',
      locality: 'San Francisco',
      csr_attributes: { 'challengePassword' => one_time_token }
    )
  end

  let(:config) do
    { 'general' => {
      'loglevel' => :debug,
      'logfile' => '/tmp/autosign.log',
      'validation_order' => validation_order
    },
      'jwt_token' => {
        'secret' => 'secret',
        'validity' => 3600,
        'journalfile' => '/tmp/autosign.journal'
      } }
  end

  before(:each) do
    allow_any_instance_of(Autosign::Config).to receive(:settings).and_return(config)
  end

  it 'decendents does not include base validator' do
    # the load order will be random at times so we need to sort in order validate we have the right classes
    expect(Autosign::Validator.validator_classes.map(&:to_s).sort)
    .to eq(["Autosign::Validators::JWT", "Autosign::Validators::Multiplexer", "Autosign::Validators::Passwordlist"])
  end

  it 'token is not reusable' do
    expect(Autosign::Validator.any_validator(one_time_token, certname, csr)).to be true
    expect(Autosign::Validator.any_validator(one_time_token, certname, csr)).to be false
  end

  it do
    expect(Autosign::Validator.validation_order).to eq [Autosign::Validators::JWT,
                                                  Autosign::Validators::Multiplexer, Autosign::Validators::Passwordlist]
  end

  it do
    expect(Autosign::Validator.validation_order(config_obj.settings, ['jwt_token'])).to eq [Autosign::Validators::JWT]                                           
  end

  context 'reduced list of validators' do
    let(:validation_order) do
      %w[
        jwt_token password_list
      ]
    end

    it do
      expect(Autosign::Validator.validation_order).to eq [Autosign::Validators::JWT,
                                                    Autosign::Validators::Passwordlist]
    end
  end

  context 'invalid validator specified' do
    let(:validation_order) do
      %w[
        token password_list blah
      ]
    end

    it do
      expect(Autosign::Validator.validation_order).to eq [Autosign::Validators::Passwordlist]
    end
  end
end
