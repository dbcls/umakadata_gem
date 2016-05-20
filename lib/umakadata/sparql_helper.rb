require 'umakadata/my_sparql_client'
require 'umakadata/logging/sparql_log'

module Umakadata
  module SparqlHelper

    def self.query(uri, query, logger:nil)
      sparql_log = Umakadata::Logging::SparqlLog.new(uri, query)
      logger.push sparql_log unless logger.nil?

      begin
        client = Umakadata::MySparqlClient.new(uri, {'read_timeout': 5 * 60})
        response = client.query(query)
        if response.nil?
          sparql_log.error = 'Failed to parse'
        end
      rescue SPARQL::Client::ClientError, SPARQL::Client::ServerError => e
        sparql_log.error = e
      rescue => e
        sparql_log.error = e
      end
      sparql_log.request = client.http_request
      sparql_log.response = client.http_response
      return response
    end

  end
end
