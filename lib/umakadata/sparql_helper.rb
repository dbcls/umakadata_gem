require 'umakadata/my_sparql_client'
require 'umakadata/logging/sparql_log'

module Umakadata
  module SparqlHelper

    def query(uri, query, logger:nil)
      sparql_log = Umakadata::Logging::SparqlLog.new(uri, query)
      logger.push sparql_log unless logger.nil?

      begin
        client = Umakadata::MySparqlClient.new(uri, {'read_timeout': 5 * 60})
        response = client.query(query)
        sparql_log.request = client.request_data
        sparql_log.response = client.response_data
        if response.nil?
          sparql_log.error = 'This content-type is not support'
          return nil
        end
        return response
      rescue SPARQL::Client::ClientError, SPARQL::Client::ServerError => e
        sparql_log.request = client.request_data
        sparql_log.error = e
        return nil
      rescue => e
        sparql_log.request = client.request_data
        sparql_log.error = e
        return nil
      end
    end

  end
end
