RSpec.describe Umakadata::SPARQL::Client do
  let(:url) { 'http://example.com/sparql' }
  let(:client) { Umakadata::SPARQL::Client.new(url, logger: { logdev: nil }) }

  before do
    WebMock.enable!
  end

  describe '#query' do
    let(:query) do
      client
        .construct(%i[s p o])
        .graph(:g)
        .where(%i[s p o])
        .limit(1)
    end

    context 'SPARQL endpoint returns polite response' do
      before do
        response = {
          status: 200,
          headers: { 'Content-Type': 'application/n-triples' },
          body: '<http://example.org/bob#me> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://xmlns.com/foaf/0.1/Person> .'
        }

        stub_request(:post, url)
          .to_return(response)
      end

      it 'returns Umakadata::Query' do
        result = client.query(query.to_s)

        expect(result).to be_a_kind_of Umakadata::Query
        expect(result.errors).to match_array []
        expect(result.warnings).to match_array []
      end
    end

    context 'SPARQL endpoint returns impolite response' do
      before do
        response = {
          status: 200,
          headers: {}, # do not return content type
          body: '<http://example.org/bob#me> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://xmlns.com/foaf/0.1/Person> .'
        }

        stub_request(:post, url)
          .to_return(response)
      end

      it 'returns Umakadata::Query with a warning' do
        result = client.query(query.to_s)

        expect(result).to be_a_kind_of Umakadata::Query
        expect(result.errors).to match_array []
        expect(result.warnings.at(0)).to match(/Inconsistent content type/)
      end
    end

    context 'SPARQL endpoint returns server error' do
      before do
        response = {
          status: [500, 'Internal Server Error'],
          body: 'Internal Server Error'
        }

        stub_request(:post, url)
          .to_return(response)

        stub_request(:get, url)
          .with(query: { query: query.to_s })
          .to_return(response)
      end

      it 'returns Umakadata::Query' do
        result = client.query(query.to_s)

        expect(result).to be_a_kind_of Umakadata::Query
        expect(result.response.status).to be 500
        expect(result.response.body).to eq 'Internal Server Error'
        expect(result.errors).to match_array []
        expect(result.warnings).to match_array []
      end
    end
  end
end
