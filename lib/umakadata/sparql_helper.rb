require 'umakadata/sparql_client'
require 'umakadata/logging/sparql_log'

module Umakadata

  module SparqlHelper

    MAGNIFICATION = lambda { |t| a, b, c = 0, 1, 0; t.times { d = a + b; a = b; b = c = d; }; c }

    def self.query(uri, query, logger: nil, options: {})
      sparql_log = Umakadata::Logging::SparqlLog.new(uri, query)
      logger.push sparql_log unless logger.nil?

      retry_count = 0
      begin
        client = Umakadata::SparqlClient.new(uri, {'read_timeout': 5 * 60}.merge(options))
        response = client.query(query)
      rescue RDF::ReaderError
        content_type = client.http_response.content_type
        sparql_log.error = "content-type: #{content_type} is inconsistent with the body of the response"
      rescue SocketError => e
        if (retry_count += 1) > 5
          sparql_log.error = SocketError.new(e.message + "\nRetry count: #{retry_count}")
        else
          sparql_log.error = "Retry count: #{retry_count}"
          sleep 10 * MAGNIFICATION.call(retry_count)
          retry
        end
      rescue => e
        sparql_log.error = e
      end
      sparql_log.request = client.http_request
      sparql_log.response = client.http_response

      return response if response.is_a?(RDF::Query::Solutions)
      return response if response.is_a?(TrueClass)
      return response if response.is_a?(FalseClass)

      sparql_log.error ||= 'Failed to parse'
      return nil
    end

  end

end
