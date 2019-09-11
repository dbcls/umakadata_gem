require 'forwardable'

module Umakadata
  # A class that represents Umakadata activity including HTTP request/response,
  # trace information, warnings and errors (if any).
  #
  # @!attribute request
  #   @return [Umakadata::Activity::Request]
  # @!attribute response
  #   @return [Umakadata::Activity::Response]
  # @!attribute result
  #   @return [Object]
  # @!attribute elapsed_time
  #   @return [Float] unit: sec
  # @!attribute trace
  #   @return [Array<String>]
  # @!attribute warnings
  #   @return [Array<String>]
  # @!attribute errors
  #   @return [Array<StandardError>]
  #
  # @since 1.0.0
  class Activity
    # A class that represents HTTP messages
    #
    # @!attribute [r] headers
    #   @return [Hash{String => String}]
    # @!attribute [r] body
    #   @return [String]
    class HTTPMessages
      attr_reader :headers
      attr_reader :body

      def initialize(headers = {}, body = nil)
        @headers = headers.map { |k, v| [k.split('-').map(&:camelize).join('-'), v] }.to_h

        class << @headers
          def respond_to_missing?(symbol, *_)
            key?(key(symbol))
          end

          def method_missing(symbol, *_) # rubocop:disable Style/MethodMissingSuper
            self[key(symbol)]
          end

          def key(symbol)
            symbol.to_s.split('_').map(&:camelize).join('-')
          end
        end

        @body = body
      end
    end

    # A class that represents HTTP request
    #
    # @!attribute [r] method
    #   @return [String] { GET | POST | PUT | DELETE | HEAD | PATCH | OPTIONS }
    # @!attribute [r] url
    #   @return [String]
    # @!attribute [r] headers
    #   @return [Hash{String => String}]
    # @!attribute [r] body
    #   @return [String]
    class Request
      extend Forwardable

      attr_reader :method
      attr_reader :url

      def_delegators :@entity, :headers, :body

      def initialize(**hash)
        @entity = HTTPMessages.new(hash.fetch(:request_headers, {}), hash[:body])
        @method = hash[:method]&.to_s&.upcase
        @url = hash[:url]&.to_s
      end

      def to_h
        %i[method url headers body].map { |k| [k, __send__(k)] }.to_h
      end
    end

    module Type
      ALIVE = :alive
      CONTENT_NEGOTIATION_ANY = :content_negotiation_any
      CONTENT_NEGOTIATION_HTML = :content_negotiation_html
      CONTENT_NEGOTIATION_RDFXML = :content_negotiation_rdfxml
      CONTENT_NEGOTIATION_TURTLE = :content_negotiation_turtle
      CLASSES = :classes
      CLASSES_HAVING_INSTANCE = :classes_having_instance
      CORS_SUPPORT = :cors_support
      EXECUTION_TIME = :execution_time
      GRAPH_KEYWORD_SUPPORT = :graph_keyword_support
      GRAPHS = :graphs
      LABELS = :labels
      LABELS_OF_CLASSES = :labels_of_classes
      LINK_TO_OTHER_URI = :link_to_other_uri
      NON_HTTP_URI_SUBJECT = :non_http_uri_subject
      NUMBER_OF_STATEMENTS = :number_of_statements
      PROPERTIES = :properties
      RETRIEVE_URI = :retrieve_uri
      SERVICE_DESCRIPTION = :service_description
      SERVICE_KEYWORD_SUPPORT = :service_keyword_support
      VOCABULARY_PREFIXES = :vocabulary_prefixes
      VOID = :void

      UNKNOWN = :unknown
    end

    # A class that represents HTTP response
    #
    # @!attribute [r] method
    #   @return [String] { GET | POST | PUT | DELETE | HEAD | PATCH | OPTIONS }
    # @!attribute [r] url
    #   @return [String]
    # @!attribute [r] status
    #   @return [Integer]
    #   @see https://developer.mozilla.org/en-US/docs/Web/HTTP/Status
    # @!attribute [r] reason_phrase
    #   @return [String]
    # @!attribute [r] headers
    #   @return [Hash{String => String}]
    # @!attribute [r] body
    #   @return [String]
    class Response
      extend Forwardable

      attr_reader :method
      attr_reader :url
      attr_reader :status
      attr_reader :reason_phrase

      def_delegators :@entity, :headers, :body

      def initialize(**hash)
        @entity = HTTPMessages.new(hash.fetch(:response_headers, {}), hash[:body])
        @method = hash[:method]&.to_s&.upcase
        @url = hash[:url]&.to_s
        @status = hash[:status]
        @reason_phrase = hash[:reason_phrase]
      end

      def to_h
        %i[method url headers body status].map { |k| [k, __send__(k)] }.to_h
      end
    end

    attr_accessor :request
    attr_accessor :response

    attr_accessor :type
    attr_accessor :result
    attr_accessor :comment

    attr_accessor :elapsed_time

    attr_accessor :trace
    attr_accessor :warnings
    attr_accessor :exceptions

    def initialize
      @request = nil
      @response = nil
      @type = nil
      @result = nil
      @comment = nil

      @elapsed_time = 0

      @trace = []
      @warnings = []
      @exceptions = []

      yield self if block_given?
    end

    def to_h
      {
        name: @type,
        comment: @comment,
        request: @request.to_h,
        response: @response.to_h,
        elapsed_time: @elapsed_time,
        trace: @trace,
        warnings: @warnings,
        exceptions: if Crawler.config.backtrace
                      @exceptions.map.with_index(1) { |e, i| [i, e.backtrace.unshift(e.message)] }.to_h
                    else
                      @exceptions.map.with_index(1) { |e, i| [i, e.message] }.to_h
                    end
      }
    end
  end
end
