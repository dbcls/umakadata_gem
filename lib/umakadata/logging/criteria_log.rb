require 'json'

module Umakadata

  module Logging

    class CriteriaLog < Log

      attr_writer :result

      def initialize
        @list = Array.new
        @result = nil
      end

      def to_h
        logs = Array.new
        @list.each { |log|
          logs.push log.to_h
        }

        {:result => @result, :logs => logs}
      end

      def as_json
        logs = Array.new
        @list.each { |log|
          logs.push log.to_h
        }

        {:result => @result, :logs => logs.to_json}
      end

    end

  end

end
