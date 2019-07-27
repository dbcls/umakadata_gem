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
        application/trig
        application/trix
        application/rdf+json
        application/rdf+xml
        application/ld+json
      ].freeze

      NULL_LOGGER = ::Logger.new(nil)

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

        options[:logger] = NULL_LOGGER

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
        options = options.dup

        # suppress parser error messages
        options[:logger] = NULL_LOGGER

        reader = RDF::Reader.for(options)

        begin
          if reader.new(@data).valid?
            callback&.call(reader, nil)
            reader.new(@data).to_a
          elsif RDF::Turtle::Format.content_type.include?(options[:content_type])
            data = @data.gsub('<>', "<#{@options[:url]}>")
            if reader.new(data).valid?
              callback&.call(reader, nil)
              reader.new(data).to_a
            end
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
        options = options.dup
        content_type = options[:content_type]

        # suppress parser error messages
        options[:logger] = NULL_LOGGER

        %i[parse_json_bindings parse_xml_bindings parse_csv_bindings parse_tsv_bindings].each do |method|
          solutions = begin
                        __send__(method, @data)
                      rescue StandardError
                        nil
                      end

          next unless solutions
          next if solutions.count.zero?

          msg = "Inconsistent content type: response = #{content_type}, parser = #{method.to_s.split('_')[1]}"
          callback&.call(solutions, msg)

          return solutions
        end

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
