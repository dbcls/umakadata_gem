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
        headers = {}
        headers['Accept'] = content_type
        headers['Accept'] ||= SERVICE_DESC_CONTEXT_TYPE.join(',')
        criteria_log = Umakadata::Logging::Log.new
        logger.push criteria_log unless logger.nil?
        args = {:headers => headers, :time_out => time_out, :logger => criteria_log}

        response = http_get(uri, args)

        if !response.is_a?(Net::HTTPSuccess)
          criteria_log.result = 'The endpoint could not return 200 HTTP response'
          return nil
        end

        sd = Umakadata::ServiceDescription.new(response)

        case sd.type
        when Umakadata::DataFormat::UNKNOWN
          criteria_log.result = 'ServiceDescription can not be retrieved in Turtle and RDF/XML format'
        when Umakadata::DataFormat::TURTLE
          criteria_log.result = 'ServiceDescription can be retrieved in Turtle format'
        when Umakadata::DataFormat::RDFXML
          criteria_log.result = 'ServiceDescription can be retrieved in RDF/XML format'
        end

        sd
      end
    end
  end
end
