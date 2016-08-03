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
      http.use_ssl = uri.scheme == 'https'
      path = uri.path.empty? ? '/' : uri.path
      path += '?' + uri.query unless uri.query.nil?
      request = Net::HTTP::Get.new(path, args[:headers])

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

      force_encode(response)
    end

    def http_get_recursive(uri, args = {}, limit = 10, logger: nil)
      raise RuntimeError, 'HTTP redirect too deep' if limit == 0

      log = Umakadata::Logging::Log.new
      logger.push log unless logger.nil?
      args[:logger] = log

      response = http_get(uri, args)

      if response.is_a? Net::HTTPRedirection
        log.result = 'HTTP response is 3xx Redirection'
        return http_get_recursive(URI(response['location']), args, limit - 1, logger: logger)
      end

      if response.is_a? Net::HTTPResponse
        log.result = "HTTP response is #{response.code} Response"
      else
        log.result = 'An error occurred in getting uri recursively'
      end
      return force_encode(response)
    end

    def force_encode(response)
      return nil if response.nil?
      body = response.body
      unless body.nil?
        body.force_encoding('UTF-8') unless body.encoding == Encoding::UTF_8
        response.body = body.encode('UTF-16BE', :invalid => :replace, :undef => :replace, :replace => '?').encode("UTF-8") unless body.valid_encoding?
      end
      return response
    end

  end

end
