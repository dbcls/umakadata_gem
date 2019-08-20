require 'active_support'
require 'active_support/core_ext'
require 'faraday'
require 'forwardable'

require 'umakadata/faraday_middleware/method_fallback'
require 'umakadata/util/numeric'

module Umakadata
  module SPARQL
    # A SPARQL 1.0/1.1 client for Umakadata
    #
    # @since 1.0.0
    class Client < Umakadata::HTTP::Client
      extend Forwardable

      autoload :Query, 'sparql/client/query'

      METHODS = %i[get post].freeze

      GRAPH_ALL = Umakadata::HTTP::ResponseParser::RDF_GRAPH_CONTENT_TYPES.join(', ').freeze
      RESULT_ALL = ::SPARQL::Client::RESULT_ALL

      DEFAULT_METHOD = :post
      DEFAULT_PROTOCOL = 1.0

      DEFAULT_OPTIONS = {
        read_timeout: 120
      }.freeze

      NULL_LOGGER = ::Logger.new(nil)

      def_delegators :sparql_client, :set_url_default_graph

      # Initialize a new sparql client
      #
      # @param [String] url URL of endpoint
      # @param [Hash{Symbol => Object}] options
      # @option options [Hash] :headers
      # @option options [Symbol] :method (DEFAULT_METHOD)
      # @option options [Number] :protocol (DEFAULT_PROTOCOL)
      # @option options [Hash] :open_timeout
      # @option options [Hash] :read_timeout
      # @option options [Hash] :retry
      # @option options [Hash] :redirect
      # @option options [Hash] :logger disable logging if { logdev => nil }
      #
      def initialize(url, **options)
        options = DEFAULT_OPTIONS.merge(options)
        super
      end

      # Executes a boolean `ASK` query.
      #
      # @return [::SPARQL::Client::Query]
      def ask(*args)
        call_query_method(:ask, *args)
      end

      # Executes a tuple `SELECT` query.
      #
      # @return [::SPARQL::Client::Query]
      def select(*args)
        call_query_method(:select, *args)
      end

      # Executes a `DESCRIBE` query.
      #
      # @return [::SPARQL::Client::Query]
      def describe(*args)
        call_query_method(:describe, *args)
      end

      # Executes a graph `CONSTRUCT` query.
      #
      # @return [::SPARQL::Client::Query]
      def construct(*args)
        call_query_method(:construct, *args)
      end

      # Executes a SPARQL query and returns the parsed results.
      #
      # @param [String, #to_s]          query
      # @param [Hash{Symbol => Object}] options
      # @option options [String] :content_type
      # @option options [Hash{Symbol => String}] :headers
      # @return [Umakadata::SPARQL::Result]
      def query(query, **options)
        @query = query
        @op = :query
        @alt_endpoint = options[:endpoint]

        is_graph = if query.respond_to?(:expects_statements?)
                     query.expects_statements?
                   else
                     query.match?(/CONSTRUCT|DESCRIBE|DELETE|CLEAR/)
                   end

        headers = options.fetch(:headers, {})
        headers[:Accept] ||= options.fetch(:content_type, is_graph ? GRAPH_ALL : RESULT_ALL)

        super(options.fetch(:method, DEFAULT_METHOD), nil, nil, headers).tap do |act|
          class << act
            attr_accessor :query
          end
          act.query = query.to_s
        end
      end

      protected

      # Alternative function to constructs an Faraday GET request
      #
      # @param [String, #to_s] path
      # @param [NilClass] _body unused
      # @param [Hash{Symbol => String}] headers
      # @return [Faraday::Request]
      def make_get_request(path, _body = nil, **headers)
        url = path ? @url.merge(path) : @url
        url.query_values = (url.query_values || {}).merge(query: @query.to_s)
        set_url_default_graph url unless @options[:graph].nil?

        super(url.request_uri, nil, headers)
      end

      # Alternative function to constructs an Faraday POST request
      #
      # @param [String, #to_s] path
      # @param [NilClass] _body unused
      # @param [Hash{Symbol => String}] headers
      # @return [Faraday::Request]
      def make_post_request(path, _body = nil, **headers)
        if @alt_endpoint.nil?
          url = path ? @url.merge(path) : @url
          set_url_default_graph url unless @options[:graph].nil?
          endpoint = url.request_uri
        else
          endpoint = @alt_endpoint
        end

        connection.build_request(:post) do |req|
          req.url(endpoint)
          req.headers.merge!(self.headers.merge(headers))

          case (@options[:protocol] || DEFAULT_PROTOCOL).to_s
          when '1.1'
            req.headers['Content-Type'] = 'application/sparql-' + (@op || :query).to_s
            req.body = @query.to_s
          when '1.0'
            req.headers['Content-Type'] = 'application/x-www-form-urlencoded'

            form_data = { (@op || :query) => @query.to_s }

            !@options[:graph].nil? &&
              (@op.eql? :query) &&
              form_data.merge!('default-graph-uri': @options[:graph])

            !@options[:graph].nil? &&
              (@op.eql? :update) &&
              form_data.merge!('using-graph-uri': @options[:graph])

            req.body = ::URI.encode_www_form(form_data)
          else
            raise ArgumentError, "unknown SPARQL protocol version: #{@options[:protocol].inspect}"
          end
        end
      end

      private

      def faraday
        super do |conn|
          conn.use Umakadata::FaradayMiddleware::MethodFallback, method_fallback_options
        end
      end

      def method_fallback_options
        {
          callback: lambda do |_, _|
            msg = 'Fallback to GET method'
            log(:info, 'method_fallback') { msg }
          end
        }
      end

      #
      # @param [Symbol] method
      # @param [Array<Object>] args
      # @return [::SPARQL::Client::Query]
      def call_query_method(method, *args)
        client = self
        result = ::SPARQL::Client::Query.send(method, *args)

        class << result
          self
        end.send(:define_method, :execute) do
          client.query(self)
        end

        result
      end

      def sparql_client
        @sparql_client ||= ::SPARQL::Client.new(@url)
      end
    end
  end
end
