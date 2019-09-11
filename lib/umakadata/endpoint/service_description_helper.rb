module Umakadata
  class Endpoint
    # Helper methods to evaluate endpoint's Service Description
    #
    # @see https://www.w3.org/TR/sparql11-service-description/
    #
    # @since 1.0.0
    module ServiceDescriptionHelper
      SSD = RDF::Vocabulary.new('http://www.w3.org/ns/sparql-service-description#')

      module Query
        SUPPORTED_LANGUAGES = RDF::Query.new do
          pattern [:s, RDF.type, SSD[:Service]]
          pattern [:s, SSD[:supportedLanguage], :language]
        end
      end

      module ServiceDescriptionMethods
        def statements
          @statements ||= RDF::Dataset.new(statements: result || [])
        end

        # @return [Array<String>]
        def supported_languages
          @supported_languages ||= statements.query(Query::SUPPORTED_LANGUAGES)
                                     .map { |x| (m = (v = x.bindings[:language].value).match(/#(.+)/)) ? m[1] : v }
                                     .uniq
        end

        # @return [RDF::Queryable]
        def void_descriptions
          @void_descriptions = begin
            op = ::SPARQL::Algebra::Expression.parse(<<~EXP.gsub(/\n\s*/, ' '))
              (describe (?s)
                (union
                  (union
                    (union
                      (bgp (triple ?s <#{RDF.type}> <#{RDF::Vocab::VOID[:Dataset]}>))
                      (bgp (triple ?s <#{RDF.type}> <#{RDF::Vocab::VOID[:DatasetDescription]}>))
                    )
                    (bgp (triple ?s <#{RDF.type}> <#{RDF::Vocab::VOID[:Linkset]}>))
                  )
                  (bgp (triple ?s <#{RDF.type}> <#{RDF::Vocab::VOID[:TechnicalFeature]}>))
                )
              )
            EXP
            statements.query(op)
          end
        end
      end

      # Execute query to obtain Service Description
      #
      # @return [Umakadata::Activity]
      def service_description
        cache(:service_description) do
          http.get(::URI.parse(url).request_uri, Accept: Umakadata::SPARQL::Client::GRAPH_ALL).tap do |act|
            act.type = Activity::Type::SERVICE_DESCRIPTION
            act.comment = if act.result.is_a?(Array) && act.result.first.is_a?(RDF::Statement)
                            "Obtained Service Description from #{act.response&.url || 'N/A'}"
                          else
                            "Failed to obtain Service Description from #{act.response&.url || 'N/A'}"
                          end

            class << act
              include ServiceDescriptionMethods
            end
          end
        end
      end
    end
  end
end
