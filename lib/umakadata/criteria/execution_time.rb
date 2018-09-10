require 'umakadata/sparql_helper'
require 'umakadata/logging/log'
require 'socket'

module Umakadata
  module Criteria
    module ExecutionTime

      TARGET_QUERY = <<-'SPARQL'
SELECT DISTINCT (COUNT(?class) AS ?c)
WHERE {[] a ?class .}
SPARQL

      def execution_time(uri, logger: nil)
        base_query_log = Umakadata::Logging::Log.new
        logger.push base_query_log unless logger.nil?
        base_response_time = self.base_response_time(uri, base_query_log)
        base_query_log.result = "TCP connection " + (base_response_time.nil? ? "is N/A" : "takes #{base_response_time} second on average")

        target_query_log = Umakadata::Logging::Log.new
        logger.push target_query_log unless logger.nil?
        target_response_time = self.response_time(uri, TARGET_QUERY, target_query_log)
        target_query_log.result = "#{TARGET_QUERY.gsub(/\n/,'')} " + (target_response_time.nil? ? "is N/A" : "takes #{target_response_time} second")

        if base_response_time.nil? || target_response_time.nil?
          logger.result = "Execution time is N/A" unless logger.nil?
          return nil
        end
        execution_time = target_response_time - base_response_time
        if execution_time < 0.0
          logger.result = "Execution time is invalid (#{execution_time})" unless logger.nil?
        else
          logger.result = "Execution time takes #{execution_time} second" unless logger.nil?
        end
        return execution_time
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

      def base_response_time(uri, logger = nil)
        trials = 5
        uri = URI.parse(uri.to_s) unless uri.is_a?(URI)

        response_times = trials.times.map do |n|
          log = Umakadata::Logging::Log.new
          logger.push log unless logger.nil?

          start_time = Time.now
          begin
            socket = TCPSocket.new(uri.host, uri.port)
          rescue SocketError
            log.result = 'TCP connection is not Success'
            next
          end
          response_time = Time.now - start_time
          socket.close
          log.result = "(#{n+1}) TCP connection takes #{response_time} second"
          response_time
        end

        return nil if response_times.compact.size != trials
        return response_times.sum.to_f / response_times.size
      end
    end
  end
end
