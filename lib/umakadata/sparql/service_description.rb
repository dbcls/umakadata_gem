require 'umakadata/rdf/vocabulary'

module Umakadata
  module SPARQL
    class ServiceDescription
      module Query
        SUPPORTED_LANGUAGES = ::RDF::Query.new do
          pattern [:s, ::RDF.type, RDF::Vocabulary::SSD[:Service]]
          pattern [:s, RDF::Vocabulary::SSD[:supportedLanguage], :language]
        end
      end

      VOID_DESCRIPTION_TYPES = [
        RDF::Vocabulary::SSD[:Dataset],
        RDF::Vocabulary::SSD[:Graph],
        ::RDF::Vocab::VOID[:Dataset],
        ::RDF::Vocab::VOID[:DatasetDescription],
        ::RDF::Vocab::VOID[:Linkset],
        ::RDF::Vocab::VOID[:TechnicalFeature]
      ]

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
        return @void_descriptions if @void_descriptions

        subjects = @dataset.select { |st| st.predicate == ::RDF.type && VOID_DESCRIPTION_TYPES.include?(st.object) }
                           .map(&:subject)

        statements = @dataset.select { |st| subjects.include?(st.subject) }

        @void_descriptions = ::RDF::Dataset.new(statements: statements || [])
      end
    end
  end
end
