require 'umakadata/error_helper'

module Umakadata
  module Criteria
    module CoolURI

      include Umakadata::ErrorHelper

      def cool_uri_rate(uri)
        rate = 0
        rate += 25 if uri.host !~ /\d+\.\d+\.\d+\.\d+/
        rate += 25 if uri.port == 80
        rate += 25 if uri.query.nil?
        rate += 25 if uri.to_s.length <= 30
        return rate
      end
    end
  end
end
