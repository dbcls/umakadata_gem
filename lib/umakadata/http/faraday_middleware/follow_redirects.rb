require 'faraday_middleware'

module Umakadata
  module FaradayMiddleware
    class FollowRedirects < ::FaradayMiddleware::FollowRedirects
      DEFAULT_OPTIONS = {
        limit: 10,
        standards_compliant: true
      }.freeze

      def initialize(app, **options)
        super(app, DEFAULT_OPTIONS.merge(options))
      end
    end
  end
end
