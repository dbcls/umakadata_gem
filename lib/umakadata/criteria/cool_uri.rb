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
          cool_uri_log.host = 'Matched rule. plus 25 points'
        else
          cool_uri_log.host = 'Could not match rule'
        end
        if uri.port == 80
          rate += 25
          cool_uri_log.port = 'Matched rule. plus 25 points'
        else
          cool_uri_log.port = 'Could not match rule'
        end
        if uri.query.nil?
          rate += 25
          cool_uri_log.query = 'Matched rule. plus 25 points'
        else
          cool_uri_log.query = 'Could not match rule'
        end
        if uri.to_s.length <= 30
          rate += 25
          cool_uri_log.length = 'Matched rule. plus 25 points'
        else
          cool_uri_log.length = 'Could not match rule'
        end

        criteria_log.result = "Cool URI Score is #{rate}"
        return rate
      end
    end
  end
end
