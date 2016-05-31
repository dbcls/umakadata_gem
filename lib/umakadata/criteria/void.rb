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

      def well_known_uri(uri)
        URI::HTTP.build({:host => uri.host, :path => WELL_KNOWN_VOID_PATH})
      end

      def void_on_well_known_uri(uri, time_out = 10, logger: nil)
        log = Umakadata::Logging::Log.new
        logger.push log unless logger.nil?
        args = {
          :time_out => time_out,
          :logger => log
        }
        response = http_get_recursive(well_known_uri, args)

        if !response.is_a?(Net::HTTPSuccess)
          log.result = 'The endpoint could not return 200 HTTP response'
          return nil
        end

        void = Umakadata::VoID.new(response, logger: log)
        return void
      end

    end
  end
end
