require 'net/http'
require 'umakadata/logging/http_log'

module Umakadata

  module HTTPHelper

    def http_get(uri, args = {})
      args = {
        :time_out => 10
      }.merge(args)

      uri = URI.parse(uri.to_s) unless uri.is_a?(URI)

      http = Net::HTTP.new(uri.host, uri.port)
      http.open_timeout = args[:time_out]

      request = Net::HTTP::Get.new(uri.path.empty? ? '/' : uri.path, args[:headers])

      http_log = Umakadata::Logging::HttpLog.new(uri, request)

      execute_request(http, request, http_log, args)
    end

    def http_post(uri, form_data, args = {})
      args = {
        :time_out => 10
      }.merge(args)

      uri = URI.parse(uri.to_s) unless uri.is_a?(URI)

      http = Net::HTTP.new(uri.host, uri.port)
      http.open_timeout = args[:time_out]

      request = Net::HTTP::Post.new(uri.path.empty? ? '/' : uri.path, args[:headers])
      request.set_form_data(form_data, ';')

      http_log = Umakadata::Logging::HttpLog.new(uri, request)

      execute_request(http, request, http_log, args)
    end

    def execute_request(http, request, http_log, args = {})
      begin
        response = http_log.response = http.start { |h|
          h.request(request)
        }
      rescue => e
        http_log.error = e
      end

      # append a log object to log container
      log = args[:logger]
      log.push http_log unless log.nil?

      response
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
