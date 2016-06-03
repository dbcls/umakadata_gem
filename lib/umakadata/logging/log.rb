require 'json'

module Umakadata

  module Logging

    class Log

      attr_writer :result

      def initialize
        @list = Array.new
        @result = nil
      end

      def push(log)
        @list.push log
      end

      def to_h
        context = Array.new
        @list.each { |log|
          context.push log.to_h
        }

        {:result => @result, :context => context}
      end

      def as_json
        context = Array.new
        @list.each { |log|
          context.push log.to_h
        }

        {:result => @result, :context => context}.to_json
      end
    end

    module Util
      def force_encode(obj)
        return obj unless obj.is_a? String
        obj.force_encoding('ASCII-8BIT').encode('UTF-8', :invalid => :replace, :undef => :replace, :replace => '?')
      end
    end

    Request = Struct.new(:request) do
      include Umakadata::Logging::Util
      def to_h
        case request
          when Net::HTTP::Get
            {:method => 'GET', :header => request.each.to_h}
          when Net::HTTP::Post
            {:method => 'POST', :header => request.each.to_h, :body => force_encode(request.body)}
          else
            {:error => "Unknown type #{request.inspect}"}
        end
      end
    end

    Response = Struct.new(:response) do
      include Umakadata::Logging::Util
      def to_h
        case response
          when Net::HTTPResponse
            {:code => response.code, :header => response.each.to_h, :body => force_encode(response.body)}
          else
            {:error => "Unknown type #{response.inspect}"}
        end
      end
    end

    Error = Struct.new(:exception) do
      def to_s
        case exception
        when StandardError
          exception.message
        else
          exception.to_s
        end
      end
    end

  end

end
