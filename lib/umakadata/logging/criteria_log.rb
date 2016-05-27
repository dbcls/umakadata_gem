require 'json'
require 'umakadata/logging/log'

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

    end

  end

end