require 'spec_helper'

describe 'Umakadata' do
  describe 'Criteria' do
    describe 'Liveness' do

      describe '#alive?' do

        let(:test_class) { Struct.new(:target) { include Umakadata::Criteria::Liveness } }
        let(:target) { test_class.new }

        before do
          @uri = URI('http://example.com')
        end

        it 'should return true when Umakadata::SparqlHelper query function returns HTTPResponse and has options that contains :method key to :get value' do
          query = 'SELECT * WHERE {?s ?p ?o} LIMIT 1'
          allow(Umakadata::SparqlHelper).to receive(:query).and_raise(@uri, query, logger: nil, options: {method: :get}).and_return(Net::HTTPResponse)
          expect(target.alive?(@uri, 10)).to be true
        end

        it 'should return true when Umakadata::SparqlHelper query function returns HTTPResponse and has options that contains :method key to :post value' do
          query = 'SELECT * WHERE {?s ?p ?o} LIMIT 1'
          allow(Umakadata::SparqlHelper).to receive(:query).and_raise(@uri, query, logger: nil, options: {method: :post}).and_return(Net::HTTPResponse)
          expect(target.alive?(@uri, 10)).to be true
        end

        it 'should return false when Umakadata::SparqlHelper query function returns 200 HTTPResponse' do
          query = 'SELECT * WHERE {?s ?p ?o} LIMIT 1'
          allow(Umakadata::SparqlHelper).to receive(:query).with(@uri, query, logger: nil, options: {method: :get}).and_return(nil)
          allow(Umakadata::SparqlHelper).to receive(:query).with(@uri, query, logger: nil, options: {method: :post}).and_return(nil)

          expect(target.alive?(@uri, 10)).to be false
        end

      end
    end
  end
end
