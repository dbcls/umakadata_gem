require 'forwardable'

OpenStruct.new

module Umakadata
  class Query
    class HTTPEntity
      attr_reader :headers
      attr_accessor :body

      def initialize(headers = {}, body = nil)
        @headers = headers.map { |k, v| [k.split('-').map(&:camelize).join('-'), v] }.to_h

        class << @headers
          def respond_to_missing?(*_)
            true
          end

          def method_missing(symbol, *_) # rubocop:disable Style/MethodMissingSuper
            self[key(symbol)] || nil
          end

          def key(symbol)
            symbol.to_s.split('_').map(&:camelize).join('-')
          end
        end

        @body = body
      end
    end

    class Request
      extend Forwardable

      attr_reader :method
      attr_reader :url

      def_delegators :@entity, :headers, :body

      def initialize(**hash)
        @entity = HTTPEntity.new(hash.fetch(:request_headers, {}), hash[:body])
        @method = hash[:method]&.to_s&.upcase
        @url = hash[:url]&.to_s
      end

      def to_h
        %i[method url headers body].map { |k| [k, __send__(k)] }.to_h
      end
    end

    class Response
      extend Forwardable

      attr_reader :method
      attr_reader :url
      attr_reader :status
      attr_reader :reason_phrase

      def_delegators :@entity, :headers, :body

      def initialize(**hash)
        @entity = HTTPEntity.new(hash.fetch(:response_headers, {}), hash[:body])
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

    attr_accessor :result

    attr_accessor :elapsed_time

    attr_accessor :trace
    attr_accessor :warnings
    attr_accessor :errors

    def initialize
      @trace = []
      @warnings = []
      @errors = []

      yield self if block_given?
    end
  end
end
