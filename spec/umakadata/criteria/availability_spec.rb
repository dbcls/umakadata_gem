RSpec.describe Umakadata::Criteria::Availability do
  let(:url) { 'http://example.com/sparql' }

  let(:endpoint) { Umakadata::Endpoint.new(url, logger: { logdev: nil }) }
  let(:availability) { Umakadata::Criteria::Availability.new(endpoint) }

  before do
    WebMock.enable!
  end

  describe '#alive' do
    context 'endpoint returns 500 status for any queries' do
      let(:response) do
        {
          status: 500,
          headers: { 'Content-Type': 'text/plain' },
          body: '500 Internal Server Error'
        }
      end

      before do
        stub_request(:post, url)
          .to_return(response)
        stub_request(:get, url)
          .with(query: hash_including({}))
          .to_return(response)
      end

      it { expect(availability.alive.value).to be_falsey }
    end

    context 'endpoint supports GRAPH keyword' do
      before do
        stub_request(:post, url)
          .to_return(response)
      end

      context 'endpoint returns expected response' do
        let(:response) do
          {
            status: 200,
            headers: { 'Content-Type': 'application/n-triples' },
            body: '<http://example.org/bob#me> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://xmlns.com/foaf/0.1/Person> .'
          }
        end

        it { expect(availability.alive).to be_truthy }
      end

      context 'endpoint returns response but content type is inconsistent' do
        let(:response) do
          {
            status: 200,
            headers: { 'Content-Type': 'text/html' },
            body: '<http://example.org/bob#me> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://xmlns.com/foaf/0.1/Person> .'
          }
        end

        it { suppress_stderr { expect(availability.alive).to be_truthy } }
      end

      context 'endpoint returns empty response' do
        let(:response) do
          {
            status: 200,
            headers: { 'Content-Type': 'application/rdf+xml' },
            body: ''
          }
        end

        it { expect(availability.alive).to be_truthy }
      end
    end

    context 'endpoint does not support GRAPH keyword' do
      before do
        stub_request(:post, url)
          .with(body: { query: 'CONSTRUCT { ?s ?p ?o . } WHERE { GRAPH ?g { ?s ?p ?o . } } LIMIT 1' })
          .to_return(status: 500)
        stub_request(:get, url)
          .with(query: { query: 'CONSTRUCT { ?s ?p ?o . } WHERE { GRAPH ?g { ?s ?p ?o . } } LIMIT 1' })
          .to_return(status: 500)
        stub_request(:post, url)
          .with(body: { query: 'CONSTRUCT { ?s ?p ?o . } WHERE { ?s ?p ?o . } LIMIT 1' })
          .to_return(response)
      end

      context 'endpoint returns expected response' do
        let(:response) do
          {
            status: 200,
            headers: { 'Content-Type': 'application/n-triples' },
            body: '<http://example.org/bob#me> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://xmlns.com/foaf/0.1/Person> .'
          }
        end

        it { expect(availability.alive).to be_truthy }
      end
    end
  end
end
