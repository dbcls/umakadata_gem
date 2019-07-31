require 'faraday'

module Umakadata
  module FaradayMiddleware
    class Retry < Faraday::Request::Retry
      DEFAULT_OPTIONS = {
        max: 3,
        interval: 10,
        backoff_factor: 2,
        methods: %i[get post]
      }.freeze

      def initialize(app, **options)
        super(app, DEFAULT_OPTIONS.merge(options))
      end
    end
  end
end
