require 'forwardable'

module Umakadata
  module HTTP
    class ResponseParser
      extend Forwardable

      RESULT_BOOL = Regexp.new(Regexp.escape(::SPARQL::Client::RESULT_BOOL)).freeze
      RESULT_JSON = Regexp.new(Regexp.escape(::SPARQL::Client::RESULT_JSON)).freeze
      RESULT_XML = Regexp.new(Regexp.escape(::SPARQL::Client::RESULT_XML)).freeze
      RESULT_CSV = Regexp.new(Regexp.escape(::SPARQL::Client::RESULT_CSV)).freeze
      RESULT_TSV = Regexp.new(Regexp.escape(::SPARQL::Client::RESULT_TSV)).freeze

      RDF_GRAPH_CONTENT_TYPES = %w[
        text/turtle
        text/n3
        application/n-triples
        application/n-quads
        application/rdf+xml
        application/rdf+json
        application/ld+json
        application/trig
        application/trix
      ].freeze

      class << self
        #
        # @param [Umakadata::Activity::Response] response
        # @return [RDF::Query::Solutions, RDF::Enumerable, true, false, nil]
        def parse(response, &block)
          new(response.body, url: response.url, content_type: response.headers.content_type, callback: block).parse
        end
      end

      #
      # @param [String] data response body
      # @param [Hash{Symbol => Object}] options
      # @option options [#to_s] :url used if response turtle uses <> as IRI
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

        case options[:content_type]
        when RESULT_BOOL
          true
        when RESULT_JSON
          parse_json_bindings(@data)
        when RESULT_XML
          parse_xml_bindings(@data)
        when RESULT_CSV
          parse_csv_bindings(@data)
        when RESULT_TSV
          parse_tsv_bindings(@data)
        else
          parse_rdf_serialization(options) || parse_any_rdf_serialization(options) || parse_any_rdf_bindings(options)
        end
      end

      #
      # @param [Hash{Symbol => Object}] options
      # @option options [String] :content_type
      # @return [RDF::Enumerable, nil]
      def parse_rdf_serialization(**options)
        options = @options.merge(options)
        return unless (reader = RDF::Reader.for(options))

        data = @data
        begin
          options = options.merge(validate: true, logger: ::Logger.new(nil))
          reader.new(data, options).to_a.tap { callback&.call(reader, nil) }
        rescue StandardError
          if !@retry && RDF::Turtle::Format.content_type.include?(options[:content_type])
            data = data.gsub(/<(#[^>]*)?>/, options[:url] ? "<#{options[:url]}\\1>" : '[]')
            @retry = true
            retry
          end
          nil
        end
      end

      #
      # @param [Hash{Symbol => Object}] options
      # @option options [String] :content_type
      # @return [RDF::Enumerable, nil]
      def parse_any_rdf_serialization(**options)
        options = @options.merge(options)
        content_type = options[:content_type]

        RDF_GRAPH_CONTENT_TYPES.each do |type|
          options[:content_type] = type

          next unless (reader = parse_rdf_serialization(options))

          msg = content_type != type ? "Inconsistent content type: response = #{content_type}, parser = #{type}" : nil
          callback&.call(reader, msg)

          return reader
        end

        nil
      end

      #
      # @param [Hash{Symbol => Object}] options
      # @option options [String] :content_type
      # @return [RDF::Query::Solutions, nil]
      def parse_any_rdf_bindings(**options)
        options = @options.merge(options)
        content_type = options[:content_type]

        # suppress parser error messages
        options[:logger] = NULL_LOGGER

        %i[parse_json_bindings parse_xml_bindings parse_csv_bindings parse_tsv_bindings].each do |method|
          solutions = delegate_to method

          next unless solutions
          next if solutions.count.zero?

          msg = "Inconsistent content type: response = #{content_type}, parser = #{method.to_s.split('_')[1]}"
          callback&.call(solutions, msg)

          return solutions
        end

        nil
      end

      def delegate_to(method)
        __send__(method, @data)
      rescue StandardError
        nil
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
