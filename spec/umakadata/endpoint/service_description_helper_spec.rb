RSpec.describe Umakadata::Endpoint::ServiceDescriptionHelper do
  let(:url) { 'http://example.com/sparql' }
  let(:http_client) { Umakadata::HTTP::Client.new(url, logger: { logdev: nil }) }

  let(:helper) do
    class Helper
      include Umakadata::Endpoint::ServiceDescriptionHelper
    end
    Helper.new
  end

  before do
    WebMock.enable!
    allow(helper).to receive(:http).and_return(http_client)
    allow(helper).to receive(:url).and_return(url)
  end

  describe '#supported_language' do
    context 'the endpoint provides service description and it contains supported language' do
      before do
        response = {
          status: 200,
          headers: { 'Content-Type': 'text/turtle; charset=UTF-8' },
          body: <<~BODY # example from http://lsd.dbcls.jp/sparql
            @prefix rdf:	<http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
            @prefix ns1:	<http://lsd.dbcls.jp/> .
            @prefix sd:	<http://www.w3.org/ns/sparql-service-description#> .
            ns1:sparql	rdf:type	sd:Service ;
              sd:endpoint	ns1:sparql ;
              sd:feature	sd:DereferencesURIs ,
                sd:UnionDefaultGraph .
            @prefix ns3:	<http://www.w3.org/ns/formats/> .
            ns1:sparql	sd:resultFormat	ns3:SPARQL_Results_CSV ,
                ns3:SPARQL_Results_JSON ,
                ns3:N3 ,
                ns3:RDF_XML ,
                ns3:SPARQL_Results_XML ,
                ns3:Turtle ,
                ns3:N-Triples ,
                ns3:RDFa ;
              sd:supportedLanguage	sd:SPARQL11Query ;
              sd:url	ns1:sparql .
          BODY
        }

        stub_request(:any, url)
          .to_return(response)
      end

      it { expect(helper.supported_language).to match ['http://www.w3.org/ns/sparql-service-description#SPARQL11Query'] }
    end

    context 'the endpoint provides service description but it does not contain supported language' do
      before do
        response = {
          status: 200,
          headers: { 'Content-Type': 'text/turtle; charset=UTF-8' },
          body: <<~BODY
            @prefix rdf:	<http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
            @prefix ns1:	<http://lsd.dbcls.jp/> .
            @prefix sd:	<http://www.w3.org/ns/sparql-service-description#> .
            ns1:sparql	rdf:type	sd:Service ;
              sd:endpoint	ns1:sparql ;
              sd:feature	sd:DereferencesURIs ,
                sd:UnionDefaultGraph .
          BODY
        }

        stub_request(:any, url)
          .to_return(response)
      end

      it { expect(helper.supported_language).to be_empty }
    end

    context 'the endpoint does not provide service description' do
      before do
        response = {
          status: 200,
          headers: { 'Content-Type': 'text/html' },
          body: <<~BODY
            <!DOCTYPE html>
            <html>
            <head>
              <title>SPARQL Endpoint</title>
              <meta http-equiv="Content-Type" content="text/html;charset=utf-8" />
            </head>
            <body>
              <h1>Virtuoso SPARQL Query Editor</h1>
            </body>
            </html>
          BODY
        }

        stub_request(:any, url)
          .to_return(response)
      end

      it { expect(helper.supported_language).to be_empty }
    end
  end
end
