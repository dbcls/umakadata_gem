require 'umakadata/logging/cool_uri_log'
require 'umakadata/logging/criteria_log'

module Umakadata
  module Criteria
    module CoolURI

      def cool_uri_rate(uri, logger: nil)
        criteria_log = Umakadata::Logging::CriteriaLog.new
        logger.push criteria_log unless logger.nil?
        cool_uri_log = Umakadata::Logging::CoolUriLog.new(uri)
        criteria_log.push cool_uri_log

        rate = 0
        if uri.host !~ /\d+\.\d+\.\d+\.\d+/
          rate += 25
          cool_uri_log.host = 'A host of URI of endpoints does not specified by IP address'
        else
          cool_uri_log.host = 'A host of URI of endpoints is specified by IP address'
        end
        if uri.port == 80
          rate += 25
          cool_uri_log.port = 'A port of URI of endpoints is 80'
        else
          cool_uri_log.port = 'A port of URI of endpoints is not 80'
        end
        if uri.query.nil?
          rate += 25
          cool_uri_log.query = 'A URI of endpoints does not contain query parameters'
        else
          cool_uri_log.query = 'A URI of endpoints contains query parameters'
        end
        if uri.to_s.length <= 30
          rate += 25
          cool_uri_log.length = 'A length of URI of endpoints is lower than 30 characters'
        else
          cool_uri_log.length = 'A length of URI of endpoints is higher than 30 characters'
        end
        criteria_log.result = "Cool URI Score is #{rate}"
        return rate
      end
    end
  end
end
