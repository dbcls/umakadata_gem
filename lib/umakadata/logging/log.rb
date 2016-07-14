require 'json'

module Umakadata

  module Logging

    class Log

      attr_accessor :result

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
        if obj.is_a? String
          obj.force_encoding('UTF-8') unless obj.encoding == Encoding::UTF_8
          obj = obj.encode('UTF-16BE', :invalid => :replace, :undef => :replace, :replace => '?').encode("UTF-8") unless obj.valid_encoding?
          begin
            obj.to_json
          rescue => e
            obj = e.message
          end
        end
        return obj
      end
    end

    Request = Struct.new(:request) do
      include Umakadata::Logging::Util
      def build
        case request
        when Net::HTTP::Get
          {:method => 'GET', :header => request.each.to_h}
        when Net::HTTP::Post
          {:method => 'POST', :header => request.each.to_h, :body => force_encode(request.body)}
        else
          "The type of request: #{force_encode(request.inspect)}"
        end
      end
    end

    Response = Struct.new(:response) do
      include Umakadata::Logging::Util
      def build
        case response
        when Net::HTTPResponse
          {:code => response.code, :header => response.each.to_h, :body => force_encode(response.body)}
        else
          "The type of response: #{force_encode(response.inspect)}"
        end
      end
    end

    Error = Struct.new(:exception) do
      include Umakadata::Logging::Util
      def build
        case exception
        when StandardError
          force_encode(exception.message)
        else
          force_encode(exception.to_s)
        end
      end
    end

  end

end
