module Umakadata
  module RDF
    class VoID
      module Query
        PUBLISHERS = ::SPARQL::Algebra::Expression.parse(<<~EXP.gsub(/\n\s*/, ' '))
          (filter
            (in
              ?type
              <#{::RDF::Vocab::VOID[:Dataset]}>
              <#{SPARQL::ServiceDescription::SSD[:Dataset]}>
              <#{SPARQL::ServiceDescription::SSD[:Graph]}>
            )
            (join
              (bgp (triple ?s <#{::RDF.type}> ?type))
              (bgp (triple ?s <#{::RDF::Vocab::DC.publisher}> ?publisher))
            )
          )
        EXP

        TRIPLES = ::SPARQL::Algebra::Expression.parse(<<~EXP.gsub(/\n\s*/, ' '))
          (filter
            (in
              ?type
              <#{::RDF::Vocab::VOID[:Dataset]}>
              <#{SPARQL::ServiceDescription::SSD[:Dataset]}>
              <#{SPARQL::ServiceDescription::SSD[:Graph]}>
            )
            (join
              (bgp (triple ?s <#{::RDF.type}> ?type))
              (bgp (triple ?s <#{::RDF::Vocab::VOID.triples}> ?triples))
            )
          )
        EXP

        LICENSES = ::SPARQL::Algebra::Expression.parse(<<~EXP.gsub(/\n\s*/, ' '))
          (filter
            (in
              ?type
              <#{::RDF::Vocab::VOID[:Dataset]}>
              <#{SPARQL::ServiceDescription::SSD[:Dataset]}>
              <#{SPARQL::ServiceDescription::SSD[:Graph]}>
            )
            (join
              (bgp (triple ?s <#{::RDF.type}> ?type))
              (bgp (triple ?s <#{::RDF::Vocab::DC.license}> ?license))
            )
          )
        EXP

        LINK_SETS = ::SPARQL::Algebra::Expression.parse(<<~EXP.gsub(/\n\s*/, ' '))
          (join
            (bgp (triple ?s <#{::RDF.type}> <#{::RDF::Vocab::VOID[:Linkset]}>))
            (bgp (triple ?s <#{::RDF::Vocab::VOID.target}> ?target))
          )
        EXP
      end

      attr_reader :dataset

      def initialize(statements)
        @dataset = ::RDF::Dataset.new(statements: statements || [])
      end

      # @return [Array<String>]
      def licenses
        @dataset.query(Query::LICENSES).map { |x| x.bindings[:license].value }.uniq
      end

      # @return [Array<String>]
      def link_sets
        @dataset.query(Query::LINK_SETS).map { |x| x.bindings[:target].value }.uniq
      end

      # @return [Integer]
      def triples
        @dataset.query(Query::TRIPLES).map { |x| x.bindings[:triples].object }.sum
      end

      # @return [Array<String>]
      def publishers
        @dataset.query(Query::PUBLISHERS).map { |x| x.bindings[:publisher].value }.uniq
      end
    end
  end
end
