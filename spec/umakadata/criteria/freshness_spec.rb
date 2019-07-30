RSpec.describe Umakadata::Criteria::Freshness do
  let(:url) { 'http://example.com/sparql' }

  let(:endpoint) { Umakadata::Endpoint.new(url, logger: { logdev: nil }) }
  let(:freshness) { Umakadata::Criteria::Freshness.new(endpoint) }

  before do
    WebMock.enable!
  end

  describe '#last_updated' do
    context 'endpoint returns VoID with statements associated with dcterms:issued' do
      let(:void) do
        {
          status: 200,
          headers: { 'Content-Type': 'application/octet-stream' },
          body: File.read(File.join(GEM_ROOT, 'examples', 'void', 'life_science_dictionary.ttl'))
        }
      end

      before do
        stub_request(:get, 'http://example.com/.well-known/void')
          .to_return(void)
      end

      it { expect(freshness.last_updated).to eq '2016-01-25 06:40:35 UTC' }
    end

    context 'endpoint does not returns VoID but ServiceDescription using VoID vocabularies' do
      let(:sd) do
        {
          status: 200,
          headers: { 'Content-Type': 'application/octet-stream' },
          body: File.read(File.join(GEM_ROOT, 'examples', 'service_description', 'example_with_void_dataset.rdf'))
        }
      end

      before do
        stub_request(:get, 'http://example.com/.well-known/void')
          .to_return(status: 500)

        stub_request(:get, url)
          .to_return(sd)
      end

      it { expect(freshness.last_updated).to eq '2019-01-03 00:00:00 UTC' }
    end

    context 'endpoint returns VoID and ServiceDescription but they do not contain update information' do
      let(:void) do
        {
          status: 200,
          headers: { 'Content-Type': 'application/octet-stream' },
          body: File.read(File.join(GEM_ROOT, 'examples', 'void', 'example.ttl'))
        }
      end

      let(:sd) do
        {
          status: 200,
          headers: { 'Content-Type': 'application/octet-stream' },
          body: File.read(File.join(GEM_ROOT, 'examples', 'service_description', 'example.rdf'))
        }
      end

      before do
        stub_request(:get, 'http://example.com/.well-known/void')
          .to_return(void)

        stub_request(:get, url)
          .to_return(sd)
      end

      it { expect(freshness.last_updated).to be_nil }
    end
  end
end
