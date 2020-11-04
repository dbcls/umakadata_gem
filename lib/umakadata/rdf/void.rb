require 'umakadata/rdf/vocabulary'

module Umakadata
  module RDF
    class VoID
      module Query
        PUBLISHERS = SPARQL::Client::Query.select(:publisher)
                       .where([:s, ::RDF::Vocab::DC.publisher, :publisher])
                       .distinct

        DATASET_TYPES = %W[<#{::RDF::Vocab::VOID[:Dataset]}>
                           <#{RDF::Vocabulary::SSD[:Dataset]}>
                           <#{RDF::Vocabulary::SSD[:Graph]}>].freeze

        TRIPLES = SPARQL::Client::Query.select(:triples)
                    .where([:s, ::RDF.type, :type])
                    .where([:s, ::RDF::Vocab::VOID.triples, :triples])
                    .filter("?type IN (#{DATASET_TYPES.join(', ')})")

        LICENSES = SPARQL::Client::Query.select(:license)
                     .where([:s, ::RDF.type, :type])
                     .where([:s, ::RDF::Vocab::DC.license, :license])
                     .filter("?type IN (#{DATASET_TYPES.join(', ')})")
                     .distinct

        LINK_SETS = SPARQL::Client::Query.select(:target)
                      .where([:s, ::RDF.type, ::RDF::Vocab::VOID[:Linkset]])
                      .where([:s, ::RDF::Vocab::VOID.target, :target])
                      .union(SPARQL::Client::Query.select(:target)
                               .where([:s, ::RDF.type, ::RDF::Vocab::VOID[:Linkset]])
                               .where([:s, ::RDF::Vocab::VOID.objectsTarget, :target]))
                      .distinct
                      .to_s
                      .sub(/WHERE ({.+} UNION {.+})/, 'WHERE { \1 }') # workaround for SPARQL::Client::Query#union
      end

      attr_reader :dataset

      def initialize(statements, **options)
        @dataset = ::RDF::Dataset.new(statements: statements || [])
        @endpoint = options[:endpoint]
      end

      # @return [Array<String>]
      def licenses
        @dataset.query(::SPARQL::Grammar.parse(Query::LICENSES)).map { |x| x.bindings[:license].value }
      end

      # @return [Array<String>]
      def link_sets
        @dataset.query(::SPARQL::Grammar.parse(Query::LINK_SETS)).map { |x| x.bindings[:target].value }
      end

      # @return [Integer]
      def triples
        @dataset.query(::SPARQL::Grammar.parse(Query::TRIPLES)).map { |x| x.bindings[:triples].object }.sum
      end

      # @return [Array<String>]
      def publishers
        query = Query::PUBLISHERS.clone
        query = query.where([:s, ::RDF::Vocab::VOID.sparqlEndpoint, ::RDF::URI(@endpoint)]) if @endpoint

        @dataset.query(::SPARQL::Grammar.parse(query)).map { |x| x.bindings[:publisher].value }
      end
    end
  end
end
