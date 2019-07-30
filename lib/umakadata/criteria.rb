module Umakadata
  #
  # @attr_reader [Umakadata::Endpoint] endpoint
  class Criteria
    attr_reader :endpoint

    #
    # @param [Umakadata::Endpoint] endpoint
    # @param [Hash{Symbol => Ojbect}] options
    def initialize(endpoint, **options)
      @endpoint = endpoint
      @options = options
    end
  end
end

require 'umakadata/criteria/availability'
require 'umakadata/criteria/freshness'
