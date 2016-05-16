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

  end

end
