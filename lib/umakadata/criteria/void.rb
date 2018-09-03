require 'umakadata/data_format'
require 'umakadata/http_helper'
require 'umakadata/void'
require 'umakadata/logging/log'
require 'uri/http'

module Umakadata
  module Criteria
    module VoID

      include Umakadata::DataFormat
      include Umakadata::HTTPHelper

      WELL_KNOWN_VOID_PATH = "/.well-known/void".freeze
      MEDIA_TYPES = [Umakadata::DataFormat::NTRIPLES, Umakadata::DataFormat::TURTLE, Umakadata::DataFormat::RDFXML,
                     Umakadata::DataFormat::N3, Umakadata::DataFormat::RDFA, Umakadata::DataFormat::JSONLD].freeze

      def well_known_uri(uri)
        URI::HTTP.build({:host => uri.host, :path => WELL_KNOWN_VOID_PATH})
      end

      def void_on_well_known_uri(uri, time_out = 10, logger: nil)
        args = {
          :time_out => time_out,
          :headers => {'Accept' => MEDIA_TYPES.join(', ')}
        }
        response = http_get_recursive(well_known_uri, args, logger: logger)

        if !response.is_a?(Net::HTTPSuccess)
          logger.result = 'The endpoint does not return 200 HTTP response' unless logger.nil?
          return
        end
        void = Umakadata::VoID.new(response, logger: logger)
        void
      end

    end
  end
end
