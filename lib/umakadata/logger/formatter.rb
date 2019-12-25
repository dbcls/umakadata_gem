require 'logger'

module Umakadata
  module Logger
    class Formatter < ::Logger::Formatter
      FORMAT = "%s, [%s#%d] %5s -- %s: %s\n".freeze

      def initialize
        super

        @datetime_format ||= '%Y-%m-%dT%H:%M:%S.%3N '
      end

      def call(severity, time, progname, msg)
        format(FORMAT, severity[0..0], format_datetime(time), $PID, severity, progname, msg2str(msg))
      end
    end

    class SimpleFormatter < ::Logger::Formatter
      FORMAT = "%5s -- %s: %s\n".freeze

      def initialize
        super
      end

      def call(severity, time, progname, msg)
        format(FORMAT, severity, progname, msg2str(msg))
      end
    end

    DEFAULT_CONFIG = {
      logdev: STDERR,
      level: ::Logger::INFO,
      formatter: Umakadata::Logger::Formatter.new
    }.freeze
  end
end
