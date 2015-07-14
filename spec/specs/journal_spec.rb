require 'spec_helper'
require 'securerandom'

context Autosign::Journal do
  let(:settings) { {'journalfile' => '/tmp/test.journal'} }
  let(:journal) { Autosign::Journal.new(settings) }
  let(:uuid) { SecureRandom.uuid }
  let(:validto) { Time.now.to_i + 900 }
  let(:data) { {'arbitrary_hey' => 'value'} }


  context 'class methods' do
    describe '.new' do
      it 'accepts a hash as the parameter' do
        expect { Autosign::Journal.new(settings) }.to_not raise_error
      end
    end
  end

  context 'instance methods' do
    describe '.add' do
      it 'Returns hash' do
        expect(journal.settings).to be_a(Hash)
      end
      it 'adds an entry to the journal with a data hash' do
        expect(journal.add(uuid, validto, data)).to be true
      end
      it 'adds an entry to the journal without a data hash' do
        expect(journal.add(uuid, validto)).to be true
      end
      it 'fail when adding two duplicate entries to the journal' do
        expect(journal.add(uuid, validto, data)).to be true
        expect(journal.add(uuid, validto, data)).to be false
      end
      it 'fail when adding an invalid UUID to the journal' do
        expect(journal.add('invalid' + uuid, validto, data)).to be false
      end
    end

  end
end
