require 'faraday'

module Umakadata
  module FaradayMiddleware
    class Logger < Faraday::Response::Logger
      DEFAULT_OPTIONS = {
        headers: true,
        bodies: false,
        callback: nil,
        on_complete_callback: nil
      }.freeze

      def initialize(app, logger = nil, **options)
        super(app, logger, DEFAULT_OPTIONS.merge(options))
      end

      def call(env)
        callback&.call(env)
        super
      end

      def on_complete(env)
        on_complete_callback&.call(env)
        super
      end

      def callback
        @options[:callback]
      end

      def on_complete_callback
        @options[:on_complete_callback]
      end
    end
  end
end
