RSpec.describe Umakadata::Endpoint::VoIDHelper do
  let(:url) { 'http://example.com/sparql' }
  let(:http_client) { Umakadata::HTTP::Client.new(url, logger: { logdev: nil }) }

  let(:helper) do
    class Helper
      include Umakadata::Cacheable
      include Umakadata::Endpoint::VoIDHelper
      include Umakadata::Endpoint::ServiceDescriptionHelper
    end
    Helper.new
  end

  before do
    WebMock.enable!
    allow(helper).to receive(:http).and_return(http_client)
    allow(helper).to receive(:url).and_return(url)
  end

  let(:void1) do
    File.read(File.join(GEM_ROOT, 'examples', 'void', 'life_science_dictionary.ttl'))
  end

  let(:void2) do
    <<~BODY # does not contain publisher
      @prefix foaf:  <http://xmlns.com/foaf/0.1/> .
      @prefix pav:   <http://purl.org/pav/> .
      @prefix xsd:   <http://www.w3.org/2001/XMLSchema#> .
      @prefix void:  <http://rdfs.org/ns/void#> .
      @prefix dcterms: <http://purl.org/dc/terms/> .
      <>      a                    void:DatasetDescription ;
              dcterms:description  "The VoID description for the RDF representation of this dataset."@en ;
              dcterms:issued       "2016-01-25T06:40:35.439Z"^^xsd:dateTime ;
              dcterms:title        "VoID Description"@en ;
              pav:createdBy        <http://voideditor.cs.man.ac.uk/6fedbb90-60c1-4711-a049-032831f0ab54> ;
              pav:createdOn        "2016-01-25T06:40:35.439Z"^^xsd:dateTime ;
              pav:createdWith      <http://voideditor.cs.man.ac.uk/> ;
              foaf:primaryTopic    <http://www.openphacts.org/aef380b9-8ad6-4d07-8f0e-212f20555d1c> .
    BODY
  end

  describe '#publisher' do
    context 'the endpoint provides VoID and it contains publisher' do
      before do
        response = {
          status: 200,
          headers: { 'Content-Type': 'application/octet-stream' },
          body: void1
        }

        stub_request(:any, 'http://example.com/.well-known/void')
          .to_return(response)
      end

      it { expect(helper.void.publishers).to match ['http://uri.dbcls.rois.ac.jp/'] }
    end

    context 'the endpoint provides VoID but it does not contain publisher' do
      before do
        response = {
          status: 200,
          headers: { 'Content-Type': 'application/octet-stream' },
          body: void2
        }

        stub_request(:any, 'http://example.com/.well-known/void')
          .to_return(response)
      end

      it { expect(helper.void.publishers).to be_empty }
    end

    context 'the endpoint does not provide VoID' do
      before do
        response = {
          status: 404,
          headers: { 'Content-Type': 'text/html' },
          body: <<~BODY
            <!DOCTYPE html>
            <html>
            <head>
              <title>Not Found</title>
              <meta http-equiv="Content-Type" content="text/html;charset=utf-8" />
            </head>
            <body>
              <h1>Not Found</h1>
            </body>
            </html>
          BODY
        }

        stub_request(:any, 'http://example.com/.well-known/void')
          .to_return(response)
        stub_request(:any, 'http://example.com/sparql')
          .to_return(response)
      end

      it { expect(helper.void.publishers).to be_empty }
    end
  end
end
