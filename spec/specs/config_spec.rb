require 'spec_helper'

context Autosign::Config do
  describe 'basic use case' do
    let(:config) { Autosign::Config.new(settings) }
    let(:settings) do
      {'config_file' => File.join(fixtures_dir, 'settings_file.yaml') }
    end

    let(:config_file_settings) do
      { 'general' =>
        {
          'loglevel' => 'INFO',
          'validation_order' => %w[
            password_list
          ]
        },
        'jwt_token' => {
          'validity' => 7200
        } }
    end

    it 'accepts a hash as the parameter' do
      expect { config }.to_not raise_error
    end

    it 'Returns hash' do
      expect(config.settings).to be_a(Hash)
    end

    it 'Settings contains general section' do
      expect(config.settings).to include(
        'general' => be_a(Hash)
      )
    end

    it 'config setting file takes precedence' do
      expect(config.settings['general']['validation_order']).to eq(['jwt_token'])
    end

  end
end
