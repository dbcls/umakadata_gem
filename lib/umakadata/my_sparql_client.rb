require 'sparql/client'

module Umakadata
  class MySparqlClient < SPARQL::Client

    attr_reader :request_data
    attr_reader :response_data

    def request(query, headers = {}, &block)
      headers['Accept'] ||= if (query.respond_to?(:expects_statements?) ?
                                      query.expects_statements? :
                                      (query =~ /CONSTRUCT|DESCRIBE|DELETE|CLEAR/))
              GRAPH_ALL
            else
              RESULT_ALL
            end

      request = send("make_#{request_method(query)}_request", query, headers)

      request.basic_auth(url.user, url.password) if url.user && !url.user.empty?
      @request_data = request

      response = @http.request(::URI.parse(url.to_s), request)

      10.times do
        if response.kind_of? Net::HTTPRedirection
          response = @http.request(::URI.parse(response['location']), request)
        else
          return block_given? ? block.call(response) : response
        end
      end

      raise ServerError, "Infinite redirect at #{url}. Redirected more than 10 times."
    end

    def response(query, options = {})
      headers = options[:headers] || {}
      headers['Accept'] = options[:content_type] if options[:content_type]
      request(query, headers) do |response|
        case response
        when Net::HTTPBadRequest  # 400 Bad Request
          raise MalformedQuery.new(response.body + " Processing query #{query}")
        when Net::HTTPClientError # 4xx
          raise ClientError.new(response.body + " Processing query #{query}")
        when Net::HTTPServerError # 5xx
          raise ServerError.new(response.body + " Processing query #{query}")
        when Net::HTTPSuccess     # 2xx
          @response_data = response
        end
      end
    end

  end
end
