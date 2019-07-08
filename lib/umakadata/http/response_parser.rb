require 'forwardable'

module Umakadata
  module HTTP
    class ResponseParser
      extend Forwardable

      RESULT_JSON = ::SPARQL::Client::RESULT_JSON
      RESULT_XML = ::SPARQL::Client::RESULT_XML
      RESULT_CSV = ::SPARQL::Client::RESULT_CSV
      RESULT_TSV = ::SPARQL::Client::RESULT_TSV
      RESULT_BOOL = ::SPARQL::Client::RESULT_BOOL
      RESULT_BRTR = ::SPARQL::Client::RESULT_BRTR

      RDF_CONTENT_TYPES = %w[
        text/turtle
        text/n3
        application/n-triples
        application/n-quads
        application/trig
        application/trix
        application/rdf+json
        application/rdf+xml
        application/ld+json
      ].freeze

      NULL_LOGGER = ::Logger.new(nil)

      class << self
        #
        # @param [Umakadata::Query::Response] response
        # @return [Object]
        def parse(response, &block)
          new(response.body, content_type: response.headers.content_type, callback: block).parse
        end
      end

      #
      # @param [String] data response body
      # @param [Hash{Symbol => Object}] options
      # @option options [String] :content_type
      # @option options [String] :callback
      def initialize(data, **options)
        @data = data
        @options = options
      end

      def_delegators :sparql_client, :parse_json_bindings, :parse_xml_bindings, :parse_csv_bindings, :parse_tsv_bindings

      # Parse a SPARQL query response.
      #
      # @param [Hash{Symbol => Object}] options
      # @option options [String] :content_type
      # @return [RDF::Query::Solutions, RDF::Enumerable, true, false, nil]
      def parse(**options)
        return if @data.blank?

        options = @options.merge(options)

        options[:logger] = NULL_LOGGER

        case options[:content_type]
        when Regexp.escape(RESULT_BOOL)
          'true'
        when Regexp.escape(RESULT_JSON)
          parse_json_bindings(@data)
        when Regexp.escape(RESULT_XML)
          parse_xml_bindings(@data)
        when Regexp.escape(RESULT_CSV)
          parse_csv_bindings(@data)
        when Regexp.escape(RESULT_TSV)
          parse_tsv_bindings(@data)
        else
          parse_rdf_serialization(options) || parse_any_rdf_serialization(options)
        end
      end

      #
      # @param [Hash{Symbol => Object}] options
      # @option options [String] :content_type
      # @return [RDF::Enumerable, nil]
      def parse_rdf_serialization(**options)
        reader = RDF::Reader.for(options)

        begin
          if reader.new(@data).valid?
            callback&.call(reader, nil)
            reader.new(@data)
          end
        rescue StandardError
          nil
        end
      end

      #
      # @param [Hash{Symbol => Object}] options
      # @option options [String] :content_type
      # @return [RDF::Enumerable, nil]
      def parse_any_rdf_serialization(**options)
        options = options.dup
        content_type = options[:content_type]

        # suppress parser error messages
        options[:logger] = NULL_LOGGER

        RDF_CONTENT_TYPES.each do |type|
          options[:content_type] = type

          next unless (reader = parse_rdf_serialization(options))

          msg = content_type != type ? "Inconsistent content type: response = #{content_type}, parser = #{type}" : nil
          callback&.call(reader, msg)

          break reader
        end
      end

      def callback
        @options[:callback]
      end

      def sparql_client
        ::SPARQL::Client
      end
    end
  end
end
