require 'json'
require 'umakadata/logging/log'

module Umakadata

  module Logging

    class HttpLog < Log

      attr_writer :response
      attr_writer :error

      def initialize(uri, request)
        @uri = uri
        @request = request
        @response = nil
        @error = nil
      end

      def to_h
        {:uri => @uri.to_s, :request => Request.new(@request).build, :response => Response.new(@response).build, :error => Error.new(@error).build}
      end

    end

  end

end
