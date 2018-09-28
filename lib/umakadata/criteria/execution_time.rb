require 'umakadata/sparql_helper'
require 'umakadata/logging/log'

module Umakadata
  module Criteria
    module ExecutionTime

      BASE_QUERY = <<-'SPARQL'
ASK {}
SPARQL

      TARGET_QUERY = <<-'SPARQL'
SELECT DISTINCT ?class 
WHERE { 
  [] a ?class . 
} 
LIMIT 100 
OFFSET %d
SPARQL

      def execution_time(uri, times: 3, logger: nil)
        measurement = times.times.map do |t|
          measure(t, uri, logger: logger)
        end

        target = measurement.collect { |x| x[0] }.compact
        base = measurement.collect { |x| x[1] }.compact

        exec_time = (target.inject(:+) / target.length) - (base.inject(:+) / base.length)
        t = exec_time > 0 ? exec_time : 0

        logger.result = "Execution time takes #{t} second" unless logger.nil?

        t
      end

      def measure(time, uri, logger: nil)
        base_query_log = Umakadata::Logging::Log.new
        logger.push base_query_log unless logger.nil?
        base_response_time = self.response_time(uri, BASE_QUERY, base_query_log)
        base_query_log.result = "#{BASE_QUERY.gsub(/\n/,'')} " + (base_response_time.nil? ? "is N/A" : "takes #{base_response_time} second")

        target_query_log = Umakadata::Logging::Log.new
        logger.push target_query_log unless logger.nil?
        target_response_time = self.response_time(uri, TARGET_QUERY % (100 * time), target_query_log)
        target_query_log.result = "#{(TARGET_QUERY  % (100 * time)).gsub(/\n/,'')} " + (target_response_time.nil? ? "is N/A" : "takes #{target_response_time} second")

        if base_response_time.nil? || target_response_time.nil?
          logger.result = "Execution time is N/A" unless logger.nil?
          return []
        end

        [target_response_time, base_response_time]
      end

      def response_time(uri, sparql_query, logger=nil)
        [:post, :get].each do |method|
          log = Umakadata::Logging::Log.new
          logger.push log unless logger.nil?
          start_time = Time.now
          response = Umakadata::SparqlHelper.query(uri, sparql_query, logger: log, options: {method: method})
          if response.nil?
            log.result = 'An error occured in checking response time for the endpoint'
            next
          end
          log.result = '200 HTTP response'
          return Time.now - start_time
        end
        nil
      end

    end
  end
end
