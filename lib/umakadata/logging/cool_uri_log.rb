require 'json'
require 'umakadata/logging/log'

module Umakadata

  module Logging

    class CoolUriLog < Log

      attr_writer :host
      attr_writer :port
      attr_writer :query
      attr_writer :length

      def initialize(uri)
        @uri = uri
        @host = nil
        @port = nil
        @query = nil
        @length = nil
      end

      def to_h
        {:host => @host, :port => @port, :query => @query, :length => @length}
      end

    end

  end

end
