require 'forwardable'

require 'umakadata/concerns/cacheable'

module Umakadata
  # A SPARQL endpoint for Umakadata
  #
  # @!attribute [r] url
  #   @return [String] the URL of the SPARQL endpoint
  # @!attribute [r] options
  #   @return [Hash]
  # @!attribute [r] exclude_graph
  #   @return [Array<String>]
  # @!attribute [r] resource_uri
  #   @return [Array<ResourceURI>]
  class Endpoint
    extend Forwardable

    include Cacheable

    attr_reader :url
    attr_reader :options
    attr_reader :exclude_graph
    attr_reader :resource_uri
    attr_reader :vocabulary_prefix_others

    attr_accessor :vocabulary_prefix

    # @param [String] url an URL of the SPARQL endpoint
    # @param [Hash{Symbol => Object}] options
    def initialize(url, **options)
      @url = url
      @options = options
      @exclude_graph = Array(options.delete(:exclude_graph))
      @resource_uri = Array(options.delete(:resource_uri))
      @vocabulary_prefix_others = Array(options.delete(:vocabulary_prefix_others))
      @criteria = {}
    end

    def basic_information
      {
        service_keyword: service_keyword_supported?,
        graph_keyword: graph_keyword_supported?,
        cors: cors_supported?
      }
    end

    # @return [Umakadata::SPARQL::Client] SPARQL Client
    def sparql
      @sparql ||= Umakadata::SPARQL::Client.new(url, **@options)
    end

    def_delegators :sparql, :query

    # @return [Umakadata::HTTP::Client] HTTP Client
    def http
      @http ||= Umakadata::HTTP::Client.new(url, **@options)
    end

    def_delegators :http, :get

    module Criteria
      def availability
        @criteria[:availability] ||= Umakadata::Criteria::Availability.new(self)
      end

      def freshness
        @criteria[:freshness] ||= Umakadata::Criteria::Freshness.new(self)
      end

      def operation
        @criteria[:operation] ||= Umakadata::Criteria::Operation.new(self)
      end

      def performance
        @criteria[:performance] ||= Umakadata::Criteria::Performance.new(self)
      end

      def usefulness
        @criteria[:usefulness] ||= Umakadata::Criteria::Usefulness.new(self)
      end

      def validity
        @criteria[:validity] ||= Umakadata::Criteria::Validity.new(self)
      end
    end
    include Criteria

    module CORS
      # Check whether if the endpoint returns CORS header
      #
      # @return [true, false] true if the endpoint returns CORS header
      #
      # @see https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS
      def cors_supported?
        cors_support.response&.headers&.dig('Access-Control-Allow-Origin') == '*'
      end

      # Execute query to check CORS support
      #
      # @return [Umakadata::Activity]
      def cors_support
        cache do
          sparql.ask(%i[s p o]).execute.tap do |act|
            act.type = Activity::Type::CORS_SUPPORT
            act.comment = if act.response&.headers&.dig('Access-Control-Allow-Origin') == '*'
                            "The response header includes 'Access-Control-Allow-Origin = *'."
                          else
                            "The response header does not include 'Access-Control-Allow-Origin = *'."
                          end
          end
        end
      end
    end
    include CORS

    module ServiceDescription
      # Execute query to obtain Service Description
      #
      # @return [Umakadata::Activity]
      def service_description
        cache do
          http.get(::URI.parse(url).request_uri, Accept: Umakadata::SPARQL::Client::GRAPH_ALL).tap do |act|
            act.type = Activity::Type::SERVICE_DESCRIPTION
            act.comment = if act.result.is_a?(::RDF::Enumerable)
                            "Obtained Service Description from #{act.response&.url || 'N/A'}"
                          else
                            "Failed to obtain Service Description from #{act.response&.url || 'N/A'}"
                          end

            class << act
              extend Forwardable

              attr_accessor :sd
              def_delegators :@sd, :supported_languages, :void_descriptions
            end

            act.sd = Umakadata::SPARQL::ServiceDescription.new(act.result)
          end
        end
      end
    end
    include ServiceDescription

    module VoID
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
        cache do
          http.get('/.well-known/void', Accept: Umakadata::SPARQL::Client::GRAPH_ALL).tap do |act|
            act.type = Activity::Type::VOID

            statements = []
            act.comment = "Failed to obtain VoID from #{act.response&.url || 'N/A'}"

            if act.result.is_a?(::RDF::Enumerable)
              statements = act.result
              act.comment = "Obtained VoID from #{act.response&.url || 'N/A'}"
            elsif (s = service_description.void_descriptions.statements).present?
              statements = s
              act.result = s
              act.comment = 'Obtained VoID from ServiceDescription'
            end

            class << act
              extend Forwardable

              attr_accessor :void
              def_delegators :@void, :licenses, :link_sets, :publishers, :triples
            end

            act.void = Umakadata::RDF::VoID.new(statements, endpoint: url)
          end
        end
      end
    end
    include VoID

    module Syntax
      # Check whether if the endpoint support graph keyword
      #
      # @return [true, false] true if the endpoint support graph keyword
      def graph_keyword_supported?
        graph_keyword_support.response&.status == 200
      end

      # Check whether if the endpoint support service keyword
      #
      # @return [true, false] true if the endpoint support service keyword
      def service_keyword_supported?
        service_keyword_support.response&.status == 200
      end

      # Execute query to check graph keyword support
      #
      # @return [Umakadata::Activity]
      def graph_keyword_support
        cache do
          sparql.construct(%i[s p o]).where(%i[s p o]).graph(:g).limit(1).execute.tap do |act|
            act.type = Activity::Type::GRAPH_KEYWORD_SUPPORT
            act.comment = if (200..299).include?(act.response&.status)
                            'The endpoint supports GRAPH keyword.'
                          else
                            'The endpoint does not support GRAPH keyword.'
                          end
          end
        end
      end

      # Execute query to check service keyword support
      #
      # @return [Umakadata::Activity]
      def service_keyword_support
        cache do
          sparql.query("CONSTRUCT { ?s ?p ?o . } WHERE { SERVICE <#{url}> { ?s ?p ?o . } } LIMIT 1").tap do |act|
            act.type = Activity::Type::SERVICE_KEYWORD_SUPPORT
            act.comment = if (200..299).include?(act.response&.status)
                            'The endpoint supports SERVICE keyword.'
                          else
                            'The endpoint does not support SERVICE keyword.'
                          end
          end
        end
      end
    end
    include Syntax
  end
end
