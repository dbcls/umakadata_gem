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
        {:uri => @uri, :request => Request.new(@request).to_h, :response => Response.new(@response).to_h, :error => Error.new(@error).to_h}
      end

    end

  end

end
