require 'json'
require 'umakadata/logging/log'

module Umakadata

  module Logging

    class SparqlLog < Log

      attr_writer :request
      attr_writer :response
      attr_writer :error

      def initialize(uri, query)
        @uri = uri
        @query = query
        @request = nil
        @response = nil
        @error = nil
      end

      def to_h
        {:uri => @uri, :query => @query, :request => Request.new(@request).to_h, :response => Response.new(@response).to_h, :error => Error.new(@error).to_h}
      end

    end

  end

end
