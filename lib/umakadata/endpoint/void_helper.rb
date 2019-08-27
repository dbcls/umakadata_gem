module Umakadata
  class Endpoint
    # Helper methods to evaluate endpoint's VoID Vocabulary
    #
    # @see https://www.w3.org/TR/void/
    #
    # @since 1.0.0
    module VoIDHelper
      module Query
        PUBLISHERS = RDF::Query.new do
          pattern [:s, RDF.type, RDF::Vocab::VOID[:Dataset]]
          pattern [:s, RDF::Vocab::DC.publisher, :publisher]
        end

        LICENSES = RDF::Query.new do
          pattern [:s, RDF.type, RDF::Vocab::VOID[:Dataset]]
          pattern [:s, RDF::Vocab::DC.license, :license]
        end

        TRIPLES = RDF::Query.new do
          pattern [:s, RDF.type, RDF::Vocab::VOID[:Dataset]]
          pattern [:s, RDF::Vocab::VOID.triples, :triples]
        end

        LINK_SETS = RDF::Query.new do
          pattern [:s, RDF.type, RDF::Vocab::VOID[:Linkset]]
          pattern [:s, RDF::Vocab::VOID.target, :target]
        end
      end

      module VoIDMethods
        def statements
          @statements ||= RDF::Dataset.new(statements: result || [])
        end

        # @return [Array<String>]
        def publishers
          @publishers ||= statements.query(Query::PUBLISHERS).map { |x| x.bindings[:publisher].value }.uniq
        end

        # @return [Array<String>]
        def licenses
          @licenses ||= statements.query(Query::LICENSES).map { |x| x.bindings[:license].value }.uniq
        end

        # @return [Integer]
        def triples
          @triples ||= statements.query(Query::TRIPLES).map { |x| x.bindings[:triples].object }.sum
        end

        def link_sets
          @link_sets ||= statements.query(Query::LINK_SETS).map { |x| x.bindings[:target].value }
        end
      end

      # Execute query to obtain VoID
      #
      # @return [Umakadata::Activity]
      #
      # @see https://www.w3.org/TR/void/#discovery
      #
      # @todo Concern about "Discovery via links in the dataset's documents"
      #   It might be necessary to obtain metadata by SPARQL query.
      #   See https://www.w3.org/TR/void/#discovery-links
      def void
        cache(:void) do
          http.get('/.well-known/void', Accept: Umakadata::SPARQL::Client::GRAPH_ALL).tap do |act|
            act.type = Activity::Type::VOID
            act.comment = if act.result.is_a?(Array) && act.result.first.is_a?(RDF::Statement)
                            "Obtained VoID from #{act.response&.url || 'N/A'}"
                          else
                            "Failed to obtain VoID from #{act.response&.url || 'N/A'}"
                          end

            class << act
              include VoIDMethods
            end
          end
        end
      end
    end
  end
end
