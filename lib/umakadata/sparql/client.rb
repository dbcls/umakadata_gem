require 'active_support'
require 'active_support/core_ext'
require 'faraday'
require 'forwardable'

require 'umakadata/faraday_middleware/follow_redirects'
require 'umakadata/faraday_middleware/logger'
require 'umakadata/faraday_middleware/method_fallback'
require 'umakadata/faraday_middleware/retry'

require 'umakadata/util/numeric'

module Umakadata
  module SPARQL
    # A SPARQL 1.0/1.1 client for Umakadata
    #
    # @since 1.0.0
    class Client < ::SPARQL::Client
      extend Forwardable

      USER_AGENT = "Umaka-Crawler/#{Umakadata::VERSION} by DBCLS (umakadata@dbcls.jp)".freeze

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

      GRAPH_ALL = RDF_CONTENT_TYPES.join(', ').freeze

      NULL_LOGGER = ::Logger.new(nil)

      LOGGER_DEFAULT_OPTIONS = {
        level: ::Logger::INFO,
        formatter: Umakadata::Logger::Formatter.new
      }.freeze

      # Initialize a new sparql client
      #
      # @param [String] url URL of endpoint
      # @param [Hash{Symbol => Object}] options
      #
      # @option options [Symbol] :method (DEFAULT_METHOD)
      # @option options [Number] :protocol (DEFAULT_PROTOCOL)
      # @option options [Hash] :headers
      # @option options [Hash] :read_timeout
      # @option options [Hash] :retry
      # @option options [Hash] :redirect
      # @option options [Hash] :logger disable logging if logdev is nil
      #
      def initialize(url, **options, &block)
        @options = options

        logger_device = options[:logger]&.key?(:logdev) ? options[:logger][:logdev] : STDERR

        logger_options = LOGGER_DEFAULT_OPTIONS
                           .merge(options[:logger] || {})
                           .slice(:level, :progname, :formatter, :datetime_format, :shift_period_suffix)

        @logger = ::Logger.new(logger_device, logger_options)

        super
      end

      def_delegators :@logger, :debug, :info, :warn, :error, :fatal

      # Executes a SPARQL query and returns the parsed results.
      #
      # @param  [String, #to_s]          query
      # @param  [Hash{Symbol => Object}] options
      # @option options [String] :content_type
      # @option options [Hash] :headers
      # @return [Umakadata::SPARQL::Result]
      def query(query, **options)
        @op = :query
        @alt_endpoint = options[:endpoint]

        @query = Query.new

        begin
          @query.response = response(query, options)
          @query.result = parse_response(@query.response, options)
        rescue StandardError => e
          @query.errors.push e
        end

        @query
      end

      # Executes a SPARQL query and returns the Net::HTTP::Response of the result.
      #
      # @param [String, #to_s]   query
      # @param  [Hash{Symbol => Object}] options
      # @option options [String] :content_type
      # @option options [Hash] :headers
      # @return [String]
      def response(query, **options)
        headers = options[:headers] || {}
        headers['Accept'] = options[:content_type] if options[:content_type]

        request(query, headers)
      end

      # Parse a SPARQL query response.
      #
      # @param  [Faraday::Response] response
      # @param  [Hash{Symbol => Object}] options
      # @return [Object, nil]
      def parse_response(response, **options)
        return if response.nil? || response.body.blank?

        return unless (200..299).include?(response.status)

        options = options.dup

        options[:logger] = NULL_LOGGER

        content_type = options[:content_type] || response.content_type

        case content_type
        when Regexp.escape(RESULT_BOOL)
          # Sesame-specific
          response.body == 'true'
        when Regexp.escape(RESULT_JSON)
          self.class.parse_json_bindings(response.body, nodes)
        when Regexp.escape(RESULT_XML)
          self.class.parse_xml_bindings(response.body, nodes)
        when Regexp.escape(RESULT_CSV)
          self.class.parse_csv_bindings(response.body, nodes)
        when Regexp.escape(RESULT_TSV)
          self.class.parse_tsv_bindings(response.body, nodes)
        else
          parse_any_rdf_serialization(response, options)
        end
      end

      # @param  [Faraday::Response] response
      # @param  [Hash{Symbol => Object}] options
      # @return [RDF::Enumerable]
      def parse_any_rdf_serialization(response, **options)
        options = options.dup

        options[:content_type] ||= response.content_type
        content_type = options[:content_type]
        if (rdf = parse_rdf_serialization(response, options))
          return rdf
        end

        RDF_CONTENT_TYPES.each do |type|
          options[:content_type] = type

          rdf = parse_rdf_serialization(response, options)

          next unless rdf

          @query.warnings.push(msg = "Inconsistent content type: response = #{content_type}, parser = #{type}")
          warn('response-parser') { msg }
          return rdf
        end
      end

      # @param  [Faraday::Response] response
      # @param  [Hash{Symbol => Object}] options
      # @return [RDF::Enumerable]
      def parse_rdf_serialization(response, **options)
        reader = RDF::Reader.for(options)

        begin
          reader.new(response.body) if reader.new(response.body).valid?
        rescue StandardError
          nil
        end
      end

      protected

      # Performs an HTTP request against the SPARQL endpoint.
      #
      # @param  [String, #to_s]          query
      # @param  [Hash{String => String}] headers
      # @yield  [response]
      # @yieldparam [Faraday::Response] response
      # @return [Faraday::Response, nil]
      def request(query, headers = {}, &block)
        is_graph = if query.respond_to?(:expects_statements?)
                     query.expects_statements?
                   else
                     query.match?(/CONSTRUCT|DESCRIBE|DELETE|CLEAR/)
                   end

        headers['Accept'] ||= is_graph ? GRAPH_ALL : RESULT_ALL

        request = __send__("make_#{request_method(query)}_request", query, headers)

        connection.basic_auth(url.user, url.password) if url.user && !url.user.empty?

        @query&.request = request.to_env(connection)

        begin
          response = connection.builder.build_response(connection, request)

          block_given? ? block.call(response) : response
        rescue Net::HTTP::Persistent::Error
          nil
        end
      end

      # Alternative function to constructs an Faraday GET request
      #
      # @param  [String, #to_s]          query
      # @param  [Hash{String => String}] headers
      # @return [Faraday::Request]
      # @see    http://www.w3.org/TR/sparql11-protocol/#query-via-get
      def make_get_request(query, headers = {})
        url = self.url.dup
        url.query_values = (url.query_values || {}).merge(query: query.to_s)
        set_url_default_graph url unless @options[:graph].nil?

        connection.build_request(:get) do |req|
          req.url(url.request_uri)
          req.headers.merge!(self.headers.merge(headers))
        end
      end

      # Alternative function to constructs an Faraday POST request
      #
      # @param  [String, #to_s]          query
      # @param  [Hash{String => String}] headers
      # @return [Faraday::Request]
      # @see    http://www.w3.org/TR/sparql11-protocol/#query-via-post-direct
      # @see    http://www.w3.org/TR/sparql11-protocol/#query-via-post-urlencoded
      def make_post_request(query, headers = {})
        if @alt_endpoint.nil?
          url = self.url.dup
          set_url_default_graph url unless @options[:graph].nil?
          endpoint = url.request_uri
        else
          endpoint = @alt_endpoint
        end

        connection.build_request(:post) do |req|
          req.url(endpoint)
          req.headers.merge!(self.headers.merge(headers))

          case (options[:protocol] || DEFAULT_PROTOCOL).to_s
          when '1.1'
            req.headers['Content-Type'] = 'application/sparql-' + (@op || :query).to_s
            req.body = query.to_s
          when '1.0'
            req.headers['Content-Type'] = 'application/x-www-form-urlencoded'

            form_data = { (@op || :query) => query.to_s }

            !@options[:graph].nil? &&
              (@op.eql? :query) &&
              form_data.merge!('default-graph-uri': @options[:graph])

            !@options[:graph].nil? &&
              (@op.eql? :update) &&
              form_data.merge!('using-graph-uri': @options[:graph])

            req.body = ::URI.encode_www_form(form_data)
          else
            raise ArgumentError, "unknown SPARQL protocol version: #{options[:protocol].inspect}"
          end
        end
      end

      private

      attr_reader :requested_query

      # Constructs a Faraday connection or returns cached one
      #
      # @return [Faraday::Connection]
      def connection
        @connection ||= Faraday.new(url: ::URI.parse(url.to_s)) do |conn|
          conn.use Umakadata::FaradayMiddleware::MethodFallback,
                   (@options[:switch] || {}).merge(callback: method_callback)

          conn.use Umakadata::FaradayMiddleware::Retry,
                   (@options[:retry] || {}).merge(retry_block: retry_callback)

          conn.use Umakadata::FaradayMiddleware::FollowRedirects,
                   (@options[:redirect] || {}).merge(callback: redirect_callback)

          conn.use Umakadata::FaradayMiddleware::Logger,
                   @logger,
                   (@options[:logger] || {})
                     .slice(:headers, :bodies)
                     .merge(callback: logger_callback)

          conn.headers['User-Agent'] = USER_AGENT

          conn.options[:open_timeout] = @options[:open_timeout] || 10
          conn.options[:timeout] = @options[:read_timeout] || @options[:timeout] || 60

          conn.use Faraday::Adapter::NetHttpPersistent do |http|
            http.keep_alive = @options[:keep_alive] || 120
          end
        end
      end

      def method_callback
        lambda do |_response_env, new_request_env|
          msg = 'Fallback to GET method'
          info('method_fallback') { msg }
          @query.trace.push msg

          @query&.request = new_request_env
        end
      end

      def retry_callback
        lambda do |response_env, retry_options, retries, exception|
          sleep_amount = Retry.new(nil, retry_options).calculate_sleep_amount(retries + 1, response_env)

          warn('retry') { exception.message }
          @query.trace.push exception.message

          msg = "Try request again in #{sleep_amount} second#{'s' unless sleep_amount == 1} "\
            "(#{retries} time#{'s' unless retries == 1} left)"
          info('retry') { msg }
          @query.trace.push msg
        end
      end

      def redirect_callback
        lambda do |response_env, new_request_env|
          msg = "#{response_env.status} #{response_env.reason_phrase} -> #{response_env.response.headers['location']}"
          info('follow_redirects') { msg }
          @query.trace.push msg

          @query&.request = new_request_env
        end
      end

      def logger_callback
        lambda do |env|
          @query.trace.push "#{env.method.upcase} #{env.url}"
        end
      end
    end
  end
end
