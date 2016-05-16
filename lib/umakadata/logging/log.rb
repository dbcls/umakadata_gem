require 'json'

module Umakadata

  module Logging

    class Log

      def initialize
        @list = Array.new
      end

      def push(log)
        @list.push log
      end

      def to_h
        result = Array.new
        @list.each { |log|
          result.push log.to_h
        }
        result
      end

      def as_json
        result = Array.new
        @list.each { |log|
          result.push log.to_h
        }
        result.to_json
      end

    end

  end

end
