require 'umakadata/sparql_client'
require 'umakadata/logging/sparql_log'

module Umakadata

  module SparqlHelper

    def self.query(uri, query, logger: nil, options: {})
      sparql_log = Umakadata::Logging::SparqlLog.new(uri, query)
      logger.push sparql_log unless logger.nil?

      begin
        client = Umakadata::SparqlClient.new(uri, {'read_timeout': 5 * 60}.merge(options))
        response = client.query(query)
      rescue SPARQL::Client::ClientError, SPARQL::Client::ServerError => e
        sparql_log.error = e
      rescue => e
        sparql_log.error = e
      end
      sparql_log.request = client.http_request
      sparql_log.response = client.http_response

      if !response.is_a? Array
        sparql_log.error ||= 'Failed to parse'
        return nil
      end

      response
    end

  end

end
