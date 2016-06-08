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
        {:uri => @uri.to_s, :query => @query, :request => Request.new(@request).build, :response => Response.new(@response).build, :error => Error.new(@error).build}
      end

    end

  end

end
