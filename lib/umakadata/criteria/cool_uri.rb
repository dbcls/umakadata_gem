require 'umakadata/logging/cool_uri_log'
require 'umakadata/logging/log'

module Umakadata
  module Criteria
    module CoolURI

      def cool_uri_rate(uri, logger: nil)
        cool_uri_log = Umakadata::Logging::CoolUriLog.new(uri)
        logger.push cool_uri_log unless logger.nil?

        score = 0
        if uri.host !~ /\d+\.\d+\.\d+\.\d+/
          score += 25
          cool_uri_log.host = 'Add 25 points to score'
        else
          cool_uri_log.host = 'A Host should not be specified by IP Address'
        end
        if uri.port == 80
          score += 25
          cool_uri_log.port = 'Add 25 points to score'
        else
          cool_uri_log.port = 'A port of URI should be 80'
        end
        if uri.query.nil?
          score += 25
          cool_uri_log.query = 'Add 25 points to score'
        else
          cool_uri_log.query = 'A URI should not contain query parameters'
        end
        if uri.to_s.length <= 30
          score += 25
          cool_uri_log.length = 'Add 25 points to score'
        else
          cool_uri_log.length = 'A length of URI should be less than 30 characters'
        end

        logger.result = "Cool URI Score is #{score}" unless logger.nil?
        return score
      end
    end
  end
end
