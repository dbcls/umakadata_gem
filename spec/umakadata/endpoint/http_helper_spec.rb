RSpec.describe Umakadata::Endpoint::HTTPHelper do
  let(:url) { 'http://example.com/sparql' }
  let(:sparql_client) { Umakadata::SPARQL::Client.new(url, logger: { logdev: nil }) }

  let(:helper) do
    class Helper
      include Umakadata::Cacheable
      include Umakadata::Endpoint::HTTPHelper
    end
    Helper.new
  end

  before do
    WebMock.enable!
    allow(helper).to receive(:sparql).and_return(sparql_client)
  end

  describe '#cors_supported?' do
    context "endpoint's response header include Access-Control-Allow-Origin" do
      before do
        response = {
          status: 200,
          headers: { 'Access-Control-Allow-Origin': '*' }
        }

        stub_request(:any, url)
          .to_return(response)
      end

      it { expect(helper.cors_supported?).to be_truthy }
    end

    context "endpoint's response header does not include Access-Control-Allow-Origin" do
      before do
        response = {
          status: 200
        }

        stub_request(:any, url)
          .to_return(response)
      end

      it { expect(helper.cors_supported?).to be_falsey }
    end
  end
end
