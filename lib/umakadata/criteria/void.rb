require 'umakadata/data_format'
require 'umakadata/http_helper'
require 'umakadata/void'
require 'umakadata/error_helper'
require 'uri/http'

module Umakadata
  module Criteria
    module VoID

      include Umakadata::DataFormat
      include Umakadata::HTTPHelper
      include Umakadata::ErrorHelper

      WELL_KNOWN_VOID_PATH = "/.well-known/void".freeze

      def well_known_uri(uri)
        URI::HTTP.build({:host => uri.host, :path => WELL_KNOWN_VOID_PATH})
      end

      def void_on_well_known_uri(uri, time_out = 10)
        response = http_get_recursive(well_known_uri, {}, time_out)

        if !response.is_a?(Net::HTTPSuccess)
          if response.is_a? Net::HTTPResponse
            set_error(response.code + "\s" + response.message)
          else
            set_error(response)
          end
          return nil
        end

        void = Umakadata::VoID.new(response)

        if void.text.nil?
          set_error("Neither turtle nor rdfxml format")
        end
        return void
      end

    end
  end
end
