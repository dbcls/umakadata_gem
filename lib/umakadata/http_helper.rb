require 'net/http'

module Umakadata
  module HTTPHelper

    def http_get(uri, headers, time_out = 10)
      http = Net::HTTP.new(uri.host, uri.port)
      http.open_timeout = time_out
      path = uri.path.empty? ? '/' : uri.path

      begin
        response = http.get(path, headers)
      rescue => e
        return e.message
      end

      return response
    end

    def http_get_recursive(uri, headers = {}, time_out = 10, limit = 10)
      raise RuntimeError, 'HTTP redirect too deep' if limit == 0

      http = Net::HTTP.new(uri.host, uri.port)
      http.open_timeout = time_out

      begin
        resource = uri.path
        resource += "?" + uri.query unless uri.query.nil?
        response = http.get(resource, headers)
      rescue => e
        puts e
        return e.message
      end

      case response
      when Net::HTTPSuccess
        return response
      when Net::HTTPRedirection
        return http_get_recursive(URI(response['location']), headers, time_out, limit - 1)
      else
        return response
      end
    end

  end
end
