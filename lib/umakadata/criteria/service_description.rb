require 'umakadata/http_helper'
require 'umakadata/error_helper'
require 'umakadata/data_format'
require "umakadata/service_description"

module Umakadata
  module Criteria
    module ServiceDescription

      include Umakadata::HTTPHelper
      include Umakadata::ErrorHelper

      SERVICE_DESC_CONTEXT_TYPE = [Umakadata::DataFormat::TURTLE, Umakadata::DataFormat::RDFXML].freeze

      ##
      # A string value that describes what services are provided at the SPARQL endpoint.
      #
      # @param       [Hash] opts
      # @option opts [Integer] :time_out Seconds to wait until connection is opened.
      # @return      [Umakadata::ServiceDescription|nil]
      def service_description(uri, time_out, content_type = nil)
        headers = {}
        headers['Accept'] = content_type
        headers['Accept'] ||= SERVICE_DESC_CONTEXT_TYPE.join(',')

        response = http_get(uri, {:headers => headers, :time_out => time_out})

        if !response.is_a?(Net::HTTPSuccess)
          if response.is_a? Net::HTTPResponse
            set_error(response.code + "\s" + response.message)
          else
            set_error(response)
          end
          return nil
        end

        sd = Umakadata::ServiceDescription.new(response)

        if sd.text.nil?
          set_error("Neither turtle nor rdfxml format")
        end
        return sd
      end
    end
  end
end
