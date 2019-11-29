module Umakadata
  module SPARQL
    class ServiceDescription
      SSD = ::RDF::Vocabulary.new('http://www.w3.org/ns/sparql-service-description#')

      module Query
        SUPPORTED_LANGUAGES = ::RDF::Query.new do
          pattern [:s, ::RDF.type, SSD[:Service]]
          pattern [:s, SSD[:supportedLanguage], :language]
        end

        VOID_DESCRIPTION = ::SPARQL::Algebra::Expression.parse(<<~EXP.gsub(/\n\s*/, ' '))
          (describe (?s)
            (union
              (union
                (union
                  (union
                    (union
                      (bgp (triple ?s <#{::RDF.type}> <#{SSD[:Dataset]}>))
                      (bgp (triple ?s <#{::RDF.type}> <#{SSD[:Graph]}>))
                    )
                    (bgp (triple ?s <#{::RDF.type}> <#{::RDF::Vocab::VOID[:Dataset]}>))
                  )
                  (bgp (triple ?s <#{::RDF.type}> <#{::RDF::Vocab::VOID[:DatasetDescription]}>))
                )
                (bgp (triple ?s <#{::RDF.type}> <#{::RDF::Vocab::VOID[:Linkset]}>))
              )
              (bgp (triple ?s <#{::RDF.type}> <#{::RDF::Vocab::VOID[:TechnicalFeature]}>))
            )
          )
        EXP
      end

      attr_reader :dataset

      def initialize(statements)
        @dataset = ::RDF::Dataset.new(statements: statements || [])
      end

      # @return [Array<String>]
      def supported_languages
        @supported_languages ||= @dataset.query(Query::SUPPORTED_LANGUAGES)
                                   .map { |x| (m = (v = x.bindings[:language].value).match(/#(.+)/)) ? m[1] : v }
                                   .uniq
      end

      # @return [RDF::Queryable]
      def void_descriptions
        @void_descriptions ||= @dataset.query(Query::VOID_DESCRIPTION)
      end
    end
  end
end
