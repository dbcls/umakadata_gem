require 'json'
require 'umakadata/logging/log'

module Umakadata

  module Logging

    Request = Struct.new(:request) do
      def to_h
        case request
          when Net::HTTP::Get
            {:method => 'GET', :header => request.each.to_h}
          when Net::HTTP::Post
            {:method => 'POST', :header => request.each.to_h, :body => request.body}
          else
            {:error => "Unknown type #{request.inspect}"}
        end
      end
    end

    Response = Struct.new(:response) do
      def to_h
        case response
          when Net::HTTPResponse
            {:code => response.code, :header => response.each.to_h, :body => response.body}
          else
            {:error => "Unknown type #{response.inspect}"}
        end
      end
    end

    Error = Struct.new(:exception) do
      def to_h
        case exception
          when StandardError
            {:message => exception.message}
          else
            {:message => exception.to_s}
        end
      end
    end

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
