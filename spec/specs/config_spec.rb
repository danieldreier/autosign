require 'spec_helper'

context Autosign::Config do
  describe 'basic use case' do
    let(:settings) { {} }
    let(:config) { Autosign::Config.new }
    it 'accepts a hash as the parameter' do
      expect { Autosign::Config.new(settings) }.to_not raise_error
    end
    it 'Returns hash' do
      expect(config.settings).to be_a(Hash)
    end
    it 'Settings contains general section' do
      expect(config.settings).to include(
        'general' => be_a(Hash)
      )
    end

  end
end
