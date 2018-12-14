require 'umakadata/http_helper'
require 'umakadata/data_format'
require 'umakadata/service_description'
require 'umakadata/logging/log'

module Umakadata
  module Criteria
    module ServiceDescription

      include Umakadata::HTTPHelper

      SERVICE_DESC_CONTEXT_TYPE = [Umakadata::DataFormat::TURTLE, Umakadata::DataFormat::RDFXML].freeze

      ##
      # A string value that describes what services are provided at the SPARQL endpoint.
      #
      # @param       [Hash] opts
      # @option opts [Integer] :time_out Seconds to wait until connection is opened.
      # @return      [Umakadata::ServiceDescription|nil]
      def service_description(uri, time_out, content_type = nil, logger: nil)
        log = Umakadata::Logging::Log.new
        logger.push log unless logger.nil?
        headers = {}
        headers['Accept'] = content_type
        headers['Accept'] ||= SERVICE_DESC_CONTEXT_TYPE.join(',')

        begin
          response = http_get_recursive(uri, { :headers => headers, :time_out => time_out }, :logger => log)
        rescue => e
          logger.result = e.message unless logger.nil?
          return false
        end

        unless response.is_a?(Net::HTTPSuccess)
          log.result = "HTTP response is not 2xx Success"
          logger.result = 'The endpoint does not return 200 HTTP response' unless logger.nil?
          return nil
        end

        log.result = 'The endpoint returns 200 HTTP response'
        sd = Umakadata::ServiceDescription.new(response)

        case sd.type
        when Umakadata::DataFormat::UNKNOWN
          logger.result = 'Service description is invalid (valid formats: Turtle or RDF/XML)' unless logger.nil?
        when Umakadata::DataFormat::TURTLE
          logger.result = 'Service description is in Turtle format' unless logger.nil?
        when Umakadata::DataFormat::RDFXML
          logger.result = 'Service description is in RDF/XML format' unless logger.nil?
        end

        sd
      end
    end
  end
end
