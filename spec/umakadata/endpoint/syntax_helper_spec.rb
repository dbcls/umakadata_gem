RSpec.describe Umakadata::Endpoint::SyntaxHelper do
  let(:url) { 'http://example.com/sparql' }
  let(:sparql_client) { Umakadata::SPARQL::Client.new(url, logger: { logdev: nil }) }

  let(:helper) do
    class Helper
      include Umakadata::Endpoint::SyntaxHelper
    end
    Helper.new
  end

  before do
    WebMock.enable!
    allow(helper).to receive(:sparql).and_return(sparql_client)
    allow(helper).to receive(:url).and_return(url)
  end

  describe '#graph_keyword_supported?' do
    context 'the endpoint returns 200 status for the query contains GRAPH keyword' do
      before do
        response = {
          status: 200
        }

        stub_request(:any, url)
          .with(query: hash_including {})
          .to_return(response)
      end

      it { expect(helper.graph_keyword_supported?).to be_truthy }
    end

    context 'the endpoint returns 500 status for the query contains GRAPH keyword' do
      before do
        response = {
          status: 500
        }

        stub_request(:any, url)
          .with(query: hash_including {})
          .to_return(response)
      end

      it { expect(helper.cors_supported?).to be_falsey }
    end
  end
end
