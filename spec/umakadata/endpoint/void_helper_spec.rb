RSpec.describe Umakadata::Endpoint::VoIDHelper do
  let(:url) { 'http://example.com/sparql' }
  let(:http_client) { Umakadata::HTTP::Client.new(url, logger: { logdev: nil }) }

  let(:helper) do
    class Helper
      include Umakadata::Endpoint::VoIDHelper
    end
    Helper.new
  end

  before do
    WebMock.enable!
    allow(helper).to receive(:http).and_return(http_client)
    allow(helper).to receive(:url).and_return(url)
  end

  let(:void1) do
    <<~BODY # example from http://lsd.dbcls.jp/.well-known/void
      @prefix dc:    <http://purl.org/dc/elements/1.1/> .
      @prefix rdfs:  <http://www.w3.org/2000/01/rdf-schema#> .
      @prefix prov:  <http://www.w3.org/ns/prov#> .
      @prefix dcat:  <http://www.w3.org/ns/dcat#> .
      @prefix foaf:  <http://xmlns.com/foaf/0.1/> .
      @prefix pav:   <http://purl.org/pav/> .
      @prefix freq:  <http://purl.org/cld/freq/> .
      @prefix xsd:   <http://www.w3.org/2001/XMLSchema#> .
      @prefix void:  <http://rdfs.org/ns/void#> .
      @prefix dctypes: <http://purl.org/dc/dcmitype/> .
      @prefix dcterms: <http://purl.org/dc/terms/> .
      <>      a                    void:DatasetDescription ;
              dcterms:description  "The VoID description for the RDF representation of this dataset."@en ;
              dcterms:issued       "2016-01-25T06:40:35.439Z"^^xsd:dateTime ;
              dcterms:title        "VoID Description"@en ;
              pav:createdBy        <http://voideditor.cs.man.ac.uk/6fedbb90-60c1-4711-a049-032831f0ab54> ;
              pav:createdOn        "2016-01-25T06:40:35.439Z"^^xsd:dateTime ;
              pav:createdWith      <http://voideditor.cs.man.ac.uk/> ;
              foaf:primaryTopic    <http://www.openphacts.org/aef380b9-8ad6-4d07-8f0e-212f20555d1c> .
      <http://www.openphacts.org/aef380b9-8ad6-4d07-8f0e-212f20555d1c>
              a                           void:Dataset , dctypes:Dataset ;
              dcterms:accrualPeriodicity  "Don't know" ;
              dcterms:description         "An RDFized version of Life Science Dictionary which consists of various lexical resources including English-Japanese / Japanese- English dictionaries and a thesaurus using the MeSH vocabulary."@en ;
              dcterms:issued              "2014-09-03"^^xsd:date ;
              dcterms:license             <http://creativecommons.org/licenses/by-nd/3.0/deed.ja> ;
              dcterms:publisher           <http://uri.dbcls.rois.ac.jp/> ;
              dcterms:title               "LSD RDF"@en ;
              pav:authoredBy              <http://voideditor.cs.man.ac.uk/6fedbb90-60c1-4711-a049-032831f0ab54> ;
              void:dataDump               <ftp://ftp.dbcls.jp/lsd/> ;
              void:distinctObjects        "1522567"^^xsd:int ;
              void:distinctSubjects       "1943120"^^xsd:int ;
              void:sparqlEndpoint         <http://lsd.dbcls.jp/sparql> ;
              void:triples                "8546367"^^xsd:int ;
              void:exampleResource        <http://purl.jp/bio/10/lsd/mesh/D013047> ;
              void:uriLookupEndpoint      <http://lsd.dbcls.jp/fct/> ;
              void:vocabulary             <http://purl.jp/bio/10/lsd/ontology/201209> ;
              void:vocabulary             <http://www.w3.org/2002/07/owl#> ;
              dcat:Distribution           <http://voideditor.cs.man.ac.uk/2f4a292d-c3a7-451f-a70f-4a3d3b93145e#Datadump> ;
              dcat:landingPage            <http://lsd.dbcls.jp/portal/index_en.html> .
      <http://voideditor.cs.man.ac.uk/2f4a292d-c3a7-451f-a70f-4a3d3b93145e#Datadump>
              a                 dcat:Distribution ;
              dcat:downloadURL  <ftp://ftp.dbcls.jp/lsd/> ;
              dcat:mediaType    "text" .
      <http://voideditor.cs.man.ac.uk/6fedbb90-60c1-4711-a049-032831f0ab54>
              a                 foaf:Person ;
              foaf:family_name  "Yamamoto" ;
              foaf:givenname    "Yasunori" ;
              foaf:mbox         <mailto:yy@dbcls.rois.ac.jp> .
      <http://data.allie.dbcls.jp>
              a       void:Linkset ;
              void:target     <http://lsd-project.jp/en/index.html> ;
              void:target     <http://dbpedia.org> ;
              void:target     <https://id.nlm.nih.gov/mesh/> .
    BODY
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

      it { expect(helper.publisher).to match ['http://uri.dbcls.rois.ac.jp/'] }
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

      it { expect(helper.publisher).to be_empty }
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
      end

      it { expect(helper.publisher).to be_empty }
    end
  end
end
