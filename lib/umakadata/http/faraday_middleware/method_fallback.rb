require 'faraday'

module Umakadata
  module FaradayMiddleware
    class MethodFallback < Faraday::Response::Middleware
      DEFAULT_OPTIONS = {
        callback: nil
      }.freeze

      def initialize(app, **options)
        super(app)

        @options = DEFAULT_OPTIONS.merge(options)
      end

      def call(env)
        request_body = env[:body]

        response = @app.call(env)

        response.on_complete do |response_env|
          if !(200..399).include?(response_env.status) && env[:method] == :post
            new_request_env = update_env(response_env.dup, request_body)
            callback&.call(response_env, new_request_env)
            response = call(new_request_env)
          end
        end
        response
      end

      def update_env(env, request_body)
        env[:method] = :get
        env[:url].query = request_body
        env[:body] = nil
        env
      end

      def callback
        @options[:callback]
      end
    end
  end
end
