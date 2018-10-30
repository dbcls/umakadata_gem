require 'umakadata/sparql_client'
require 'umakadata/logging/sparql_log'

module Umakadata
  module SparqlHelper
    DEFAULT_OPTIONS = { 'read_timeout':       5 * 60,
                        raise_on_redirection: true,
                        try_any_formats:      true }.freeze

    def self.query(uri, query, logger: nil, options: {})
      sparql_log = Umakadata::Logging::SparqlLog.new(uri, query)
      logger.push sparql_log unless logger.nil?

      options = DEFAULT_OPTIONS.merge(options)
      client  = Umakadata::SparqlClient.new(uri, options)

      retry_count = 0

      begin
        response = client.query(query)
      rescue SparqlClient::HTTPTooManyRequests => e
        if e.wait_duration > 10.minute
          sparql_log.error = "The server returns HTTP 429 (Too Many Requests) but Retry-After is too long to wait."
        elsif retry_count >= 5
          sparql_log.error = "The server returns HTTP 429 (Too Many Requests) over 5 times."
        else
          sleep e.wait_duration
          retry_count += 1
          retry
        end
      rescue SparqlClient::HTTPRedirection => e
        if retry_count >= 10
          sparql_log.error = "The server returns HTTP 3xx (Multiple Choices) over 10 times."
        else
          client = Umakadata::SparqlClient.new(e.location, options)
          retry_count += 1
          retry
        end
      rescue RDF::ReaderError => e
        content_type     = client.http_response.content_type
        sparql_log.error = "content-type: #{content_type} is inconsistent with the body of the response"
        STDERR.puts [e.message, e.backtrace]
        return nil
      rescue => e
        sparql_log.error = e
        STDERR.puts [e.message, e.backtrace]
        return nil
      end

      sparql_log.request  = client.http_request if client
      sparql_log.response = client.http_response if client

      return response if response.is_a?(RDF::Query::Solutions)
      return response if response.is_a?(RDF::Reader)
      return response if response.is_a?(TrueClass)
      return response if response.is_a?(FalseClass)
      return response if response.is_a?(String)

      sparql_log.error ||= 'Failed to parse'
      return nil
    end
  end
end
