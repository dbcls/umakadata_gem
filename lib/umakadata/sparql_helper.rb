require 'umakadata/my_sparql_client'
require 'umakadata/logging/sparql_log'

module Umakadata
  module SparqlHelper

    def prepare(uri)
      @client = Umakadata::MySparqlClient.new(uri, {'read_timeout': 5 * 60}) if @uri == uri && @client == nil
      @uri = uri
    end

    def set_client(client)
      @client = client
    end

    def query(uri, query, logger:nil)
      self.prepare(uri)

      sparql_log = Umakadata::Logging::SparqlLog.new(uri, query)
      logger.push sparql_log unless logger.nil?
      begin
        response = @client.query(query)
        sparql_log.request = @client.request_data
        sparql_log.response = response
      rescue => e
        sparql_log.error = 'Empty triples'
        return nil
      end
      return response
    end

  end
end