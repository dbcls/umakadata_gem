require 'forwardable'
require 'umakadata/criteria'
require 'umakadata/endpoint/http_helper'
require 'umakadata/endpoint/service_description_helper'
require 'umakadata/endpoint/syntax_helper'
require 'umakadata/endpoint/void_helper'

module Umakadata
  # A SPARQL endpoint for Umakadata
  #
  # @!attribute [r] url
  #   @return [String] the URL of the SPARQL endpoint
  class Endpoint
    extend Forwardable

    include HTTPHelper
    include ServiceDescriptionHelper
    include SyntaxHelper
    include VoIDHelper

    attr_reader :url

    # @param [String] url an URL of the SPARQL endpoint
    def initialize(url, **options)
      @url = url
      @options = options
      @criteria = {}
    end

    # @return [Umakadata::SPARQL::Client] SPARQL Client
    def sparql
      @sparql ||= Umakadata::SPARQL::Client.new(url, **@options)
    end

    # @return [Umakadata::HTTP::Client] HTTP Client
    def http
      @http ||= Umakadata::HTTP::Client.new(url, **@options)
    end

    private

    def availability
      @criteria[:availability] ||= Criteria::Availability.new(self)
    end

    def freshness
      @criteria[:freshness] ||= Criteria::Freshness.new(self)
    end

    def_delegator :availability, :alive?
    def_delegator :freshness, :last_updated
  end
end
