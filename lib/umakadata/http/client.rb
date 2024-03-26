require 'active_support'
require 'active_support/core_ext'
require 'faraday'
require 'forwardable'

require 'umakadata/http/faraday_middleware/follow_redirects'
require 'umakadata/http/faraday_middleware/logger'
require 'umakadata/http/faraday_middleware/retry'
require 'umakadata/logger'
require 'umakadata/util/string'

module Umakadata
  module HTTP
    # A HTTP 1.0/1.1 client for Umakadata
    #
    # @since 1.0.0
    class Client
      extend Forwardable

      include StringExt

      METHODS = Set.new %i[get post put delete head patch options]

      USER_AGENT = "Umaka-Crawler/#{Umakadata::VERSION} by DBCLS (umakadata@dbcls.jp)".freeze

      #
      # @param [String] url
      # @param [Hash{Symbol => Object}] options
      # @option options [Hash] :headers
      # @option options [Integer] :open_timeout
      # @option options [Integer] :read_timeout
      # @option options [Hash] :retry
      # @option options [Hash] :redirect
      # @option options [Hash] :response_parser
      def initialize(url, **options)
        @url = ::URI.parse(url.to_s)
        @logger = Umakadata::Crawler.config.logger
        @options = options
      end

      def_delegators :@logger, :debug, :info, :warn, :error, :fatal

      # Executes a GET request
      #
      # @param  [String] path
      # @param  [Hash{Symbol => Object}] headers
      # @return [Umakadata::Activity]
      def get(path, **headers)
        query(:get, path, headers)
      end

      # Executes a HTTP request and return Activity
      #
      # @param  [String] path
      # @param  [Hash{Symbol => Object}] headers
      # @return [Umakadata::Activity]
      def query(method, path, body = nil, **headers)
        Activity.new do |act|
          t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)

          parser = nil
          begin
            request(method, path, body, headers) do |req, res|
              act.request = Activity::Request.new(**req.to_env(connection).to_h)
              act.response = Activity::Response.new(**(res&.env&.to_h || {}))
            end

            opts = {
              base_uri: URI.parse(act.response.url).tap { |x| x.query = nil }.to_s,
              content_type: act.response.headers.content_type,
              callback: -> (_, msg) { log(:warn, 'response_parser') { msg } if msg.present? }
            }.merge(@options.fetch(:response_parser, {}))

            parser = ResponseParser.new(act.response.body, **opts)

            act.result = parser.parse if (200..299).include?(act.response&.status)
          rescue StandardError
            sleep(1) # some servers refuse following connection without sleep
            act
          ensure
            if (e = parser&.errors).present?
              @warnings.concat(e)
            end
            act.exceptions = @exceptions
            act.warnings = @warnings
            act.trace = @trace
            act.elapsed_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0
          end
        end
      end

      # Executes a HTTP request and return Response
      #
      # @param [Symbol] method
      # @param [String] path
      # @param [String] body
      # @param [Hash{Symbol => Object}] headers
      #
      # @yield [request, response]
      # @yieldparam [Faraday::Request] request
      # @yieldparam [Faraday::Response] response
      #
      # @return [Faraday::Response]
      def request(method, path, body = nil, **headers, &block)
        raise ArgumentError, "unsupported http method: #{method}" unless METHODS.include?(method)

        @exceptions = []
        @warnings = []
        @trace = []

        execute_request(__send__("make_#{method}_request", path, body, headers), &block)
      end

      protected

      def execute_request(request, &block)
        response = nil
        begin
          response = connection.builder.build_response(connection, request)
        rescue StandardError => e
          log(:error, 'http_client') { e }
          raise e
        ensure
          block_given? ? block.call(request, response) : response
        end
      end

      def make_get_request(path, _body = nil, **headers)
        url = path ? @url.merge(path) : @url

        connection.build_request(:get) do |req|
          req.url(url.request_uri)
          req.headers.merge!(self.headers.merge(headers))
        end
      end

      def make_post_request(path, body = nil, **headers)
        url = path ? @url.merge(path) : @url

        connection.build_request(:post) do |req|
          req.url(url.request_uri)
          req.headers.merge!(self.headers.merge(headers))
          req.body = body if body.present?
        end
      end

      (METHODS - %i[get post]).each do |method|
        define_method("make_#{method}_request".to_sym) do |*_|
          raise NotImplementedError
        end
      end

      def headers
        @options.fetch(:headers, {})
      end

      def log(level, progname = nil, &block)
        if (ex = block&.call).respond_to?(:message)
          block = proc { "#{ex.class} - #{ex.message}" }
        end
        @logger.send(level, progname, &block) if %i[debug info warn error fatal].include?(level)

        case level
        when :info, :trace
          @trace.push(block&.call || progname)
        when :warn
          @warnings.push(block&.call || progname)
        when :error
          @exceptions.push(ex)
          @trace.push('Connection closed due to timeout.') if ex.is_a?(Faraday::TimeoutError)
        end
      end

      private

      def connection
        @connection ||= begin
          client = faraday

          client.headers['User-Agent'] = USER_AGENT
          client.options[:open_timeout] = @options.fetch(:open_timeout, 10)
          client.options[:timeout] = @options.fetch(:timeout, @options.fetch(:read_timeout, 60))

          client
        end
      end

      def faraday
        Faraday.new(url: @url) do |conn|
          conn.use Umakadata::FaradayMiddleware::Retry, retry_options
          conn.use Umakadata::FaradayMiddleware::FollowRedirects, redirect_options
          conn.use Umakadata::FaradayMiddleware::Logger, @logger, logger_options
          conn.use Faraday::Request::BasicAuthentication, @url.user, @url.password if @url.user

          yield conn if block_given?

          conn.adapter Faraday::Adapter::NetHttpPersistent do |http|
            http.keep_alive = @options.fetch(:keep_alive, 120)
          end
        end
      end

      def retry_options
        @options
          .fetch(:retry) { {} }
          .merge(retry_block: lambda do |response_env, retry_options, retries, exception|
            sleep_amount = Umakadata::FaradayMiddleware::Retry.new(nil, retry_options).calculate_sleep_amount(retries + 1, response_env)

            log(:error, 'retry') { exception }

            msg = "Try request again in #{pluralize(sleep_amount, 'second')} (#{pluralize(retries, 'time')} left)"
            log(:info, 'retry') { msg }
          end)
      end

      def redirect_options
        @options
          .fetch(:redirect) { {} }
          .merge(callback: lambda do |response_env, _|
            msg = "#{response_env.status} #{response_env.reason_phrase} - #{response_env.response.headers['location']}"
            log(:info, 'follow_redirects') { msg }
          end)
      end

      def logger_options
        {
          callback: ->(env) { log(:trace) { "#{env.method.upcase} #{env.url}" } }
        }
      end
    end
  end
end
