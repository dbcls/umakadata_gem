require 'spec_helper'

describe 'Umakadata' do
  describe 'Retriever' do

    let(:retriever) { Umakadata::Retriever.new('', '') }
    let(:sample_resource) { RDF::URI.new('http://example.org/resource') }
    let(:sample_date) { '2018-04-01' }

    describe '#last_updated' do

      context 'when dcterms:modified is used' do
        let(:ttl) { "<#{sample_resource}> <#{RDF::Vocab::DC.modified.to_s}> \"#{sample_date}\"." }

        it 'should return date and Service Description' do
          expect(retriever.last_updated(ttl, '')).to eq(
                                                         date:   Time.parse(sample_date),
                                                         source: 'Service Description')
        end

        it 'should return date and VoID' do
          expect(retriever.last_updated('', ttl)).to eq(
                                                         date:   Time.parse(sample_date),
                                                         source: 'VoID')
        end
      end

      context 'when dcterms:issued is used' do
        let(:ttl) { "<#{sample_resource}> <#{RDF::Vocab::DC.issued.to_s}> \"#{sample_date}\"." }

        it 'should return date and Service Description' do
          expect(retriever.last_updated(ttl, '')).to eq(
                                                         date:   Time.parse(sample_date),
                                                         source: 'Service Description')
        end

        it 'should return date and VoID' do
          expect(retriever.last_updated('', ttl)).to eq(
                                                         date:   Time.parse(sample_date),
                                                         source: 'VoID')
        end
      end

      context 'when neither dcterms:issued nor dcterms:modified is used' do
        let(:ttl) { "<#{sample_resource}> <http://example.org/predicate> \"#{sample_date}\"." }

        it 'should return nil' do
          expect(retriever.last_updated(ttl, ttl)).to eq(nil)
        end
      end
    end
  end
end