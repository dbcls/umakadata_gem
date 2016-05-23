require 'sparql/client'

module Umakadata
  class SparqlClient < SPARQL::Client

    attr_reader :http_request
    attr_reader :http_response

    def request(query, headers = {}, &block)
      headers['Accept'] ||= if (query.respond_to?(:expects_statements?) ?
                                      query.expects_statements? :
                                      (query =~ /CONSTRUCT|DESCRIBE|DELETE|CLEAR/))
              GRAPH_ALL
            else
              RESULT_ALL
            end

      @http_request = send("make_#{request_method(query)}_request", query, headers)

      @http_request.basic_auth(url.user, url.password) if url.user && !url.user.empty?

      @http_response = @http.request(::URI.parse(url.to_s), @http_request)

      10.times do
      if @http_response.kind_of? Net::HTTPRedirection
          @http_response = @http.request(::URI.parse(@http_response['location']), @http_request)
        else
          return block_given? ? block.call(@http_response) : @http_response
        end
      end

      raise ServerError, "Infinite redirect at #{url}. Redirected more than 10 times."
    end

  end
end
