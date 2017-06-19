require 'spec_helper'

describe 'Umakadata' do
  describe 'Linkset' do
    describe '#linksets' do

      include Umakadata::DataFormat

      let(:test_class) { Struct.new(:target) { include Umakadata::Linkset } }
      let(:target) { test_class.new }

      it 'returns empty list if triples is empty' do
        triples = []

        linksets = target.linksets triples

        expect(linksets).to be_empty
      end

      it 'returns empty list if there is no linksets' do
        turtle = <<-'TURTLE'
        @prefix foaf: <http://xmlns.com/foaf/0.1/> .

        <http://example.com>
        a foaf:Person ;
        foaf:family_name "Marley" ;
        foaf:givenname "Bob" ;
        foaf:mbox <mailto:bm@example.com> .
        TURTLE

        linksets = target.linksets triples(turtle)

        expect(linksets).to be_empty
      end

      it 'returns 3 entries if there 3 targets' do
        turtle = <<-'TURTLE'
        @prefix void: <http://rdfs.org/ns/void#> .

        <http://data.allie.dbcls.jp>
        a void:Linkset;
        void:target <http://dbpedia.org>;
        void:target <http://lsd.dbcls.jp/portal/>;
        void:target <http://lifesciencedb.jp/bdls/> .
        TURTLE

        linksets = target.linksets triples(turtle)

        expect(linksets.count).to be(3)
      end


      it 'returns 3 entries if there 3 targets after the other datasets' do
        turtle = <<-'TURTLE'
        @prefix void: <http://rdfs.org/ns/void#> .
        @prefix foaf: <http://xmlns.com/foaf/0.1/> .

        <http://example.com>
        a foaf:Person ;
        foaf:family_name "Marley" ;
        foaf:givenname "Bob" ;
        foaf:mbox <mailto:bm@example.com> .

        <http://data.allie.dbcls.jp>
        a void:Linkset;
        void:target <http://dbpedia.org>;
        void:target <http://lsd.dbcls.jp/portal/>;
        void:target <http://lifesciencedb.jp/bdls/> .
        TURTLE

        linksets = target.linksets triples(turtle)

        expect(linksets.count).to be(3)
        expect(linksets[0]).to eq(RDF::URI('http://dbpedia.org'))
        expect(linksets[1]).to eq(RDF::URI('http://lsd.dbcls.jp/portal/'))
        expect(linksets[2]).to eq(RDF::URI('http://lifesciencedb.jp/bdls/'))
      end

    end
  end
end
