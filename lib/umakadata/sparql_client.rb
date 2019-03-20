require 'sparql/client'
require 'umakadata/http_header'
require 'umakadata/data_format'

module Umakadata
  module ParserImprove
    def parse_response(response, options = {})
      content_type = options[:content_type] || response.content_type

      begin
        if response.is_a?(Net::HTTPSuccess) && content_type.is_a?(NilClass)
          raise(SPARQL::Client::ClientError, 'No content type specified in response.')
        end
        super
      rescue StandardError => e
        if content_type == DataFormat::HTML
          response
        elsif @try_any_formats
          try_any_format(response)
        else
          raise e
        end
      end
    end

    def try_any_format(response)
      content_types = RDF::Format.content_types.keys

      SparqlClient::GRAPH_RESULTS.select { |x| content_types.include?(x) }.each do |format|
        begin
          result = try_parse(response.body, format)
          if result
            return result
          end
        end
      end
    end

    def try_parse(body, format)
      return unless (klass = RDF::Reader.for(content_type: format))

      return unless (reader = klass.new(body)) && reader.valid?

      # cannot use #dup or #clone because IO won't be deep copied
      klass.new(body).each_triple.size > 0 ? klass.new(body) : nil
      # (result = reader.dup.each_triple.to_a).size > 0 ? result : nil
    end
  end

  module RequestImprove
    GRAPH_RESULTS = %w[application/n-quads application/rdf+xml application/ld+json application/n-triples
                       text/turtle text/n3 application/trix application/trig application/sparql-results+json].freeze

    def request(query, headers = {}, &block)
      unless headers['Accept']
        if expects_statements?(query)
          content_types     = RDF::Format.content_types.keys
          headers['Accept'] = GRAPH_RESULTS.select { |x| content_types.include?(x) }.join(', ')
          headers['Accept'] << ';q=0.9, text/html;q=0.8'
        end
      end

      super
    end

    def expects_statements?(query)
      (query.respond_to?(:expects_statements?) && query.expects_statements?) ||
        (query =~ /CONSTRUCT|DESCRIBE|DELETE|CLEAR/)
    end
  end
=begin
  module Logging
    require 'awesome_print'

    def pre_http_hook(request)
      puts '===== REQUEST ====='
      ap request.to_hash
      puts '-------------------'
      puts request.method + ' ' + url
      puts request.body
      puts '==================='

      super
    end

    def post_http_hook(response)
      puts '===== RESPONSE ====='
      ap response.to_hash
      puts '--------------------'
      puts response.code + ' ' + response.message
      puts response.body
      puts '===================='

      super
    end
  end
=end
  class SparqlClient < SPARQL::Client
    include Umakadata::DataFormat
    prepend ParserImprove
    prepend RequestImprove
#    prepend Logging

    attr_reader :http_request
    attr_reader :http_response

    class HTTPRedirection < StandardError
      attr_reader :location

      def initialize(msg = nil, location: nil)
        @location = location
        super(msg)
      end
    end

    class HTTPTooManyRequests < StandardError
      attr_reader :retry_after

      def initialize(msg = nil, retry_after: 10)
        @retry_after = retry_after
        super(msg)
      end

      # @return [Integer] the duration to wait in seconds
      def wait_duration
        begin
          Integer(@retry_after)
        rescue
          ((DateTime.parse(@retry_after) - DateTime.now) * 24 * 60 * 60).to_i
        end
      end
    end

    def initialize(url, options = {}, &block)
      @raise_on_redirection = options.delete(:raise_on_redirection) || false
      @try_any_formats      = options.delete(:try_any_formats) || false
      super
    end

    def pre_http_hook(request)
      request['User-Agent'] = Umakadata::HTTPHeader::USER_AGENT
      @http_request         = request
    end

    def post_http_hook(response)
      if response.kind_of? Net::HTTPTooManyRequests
        raise HTTPTooManyRequests.new(retry_after: response['Retry-After'])
      end

      if @raise_on_redirection && response.kind_of?(Net::HTTPRedirection)
        raise HTTPRedirection.new(location: response['location'])
      end

      @http_response = response
    end

  end
end
