require 'forwardable'
require 'umakadata/criteria'
require 'umakadata/endpoint/http_helper'
require 'umakadata/endpoint/service_description_helper'
require 'umakadata/endpoint/syntax_helper'
require 'umakadata/endpoint/void_helper'
require 'umakadata/util/cacheable'

module Umakadata
  # A SPARQL endpoint for Umakadata
  #
  # @!attribute [r] url
  #   @return [String] the URL of the SPARQL endpoint
  # @!attribute [r] options
  #   @return [Hash]
  # @!attribute [r] exclude_graph
  #   @return [Array<String>]
  # @!attribute [r] resource_uri
  #   @return [Array<ResourceURI>]
  class Endpoint
    extend Forwardable

    include Cacheable
    include HTTPHelper
    include ServiceDescriptionHelper
    include SyntaxHelper
    include VoIDHelper

    attr_reader :url
    attr_reader :options
    attr_reader :exclude_graph
    attr_reader :resource_uri

    # @param [String] url an URL of the SPARQL endpoint
    # @param [Hash{Symbol => Object}] options
    def initialize(url, **options)
      @url = url
      @options = options
      @exclude_graph = Array(options.delete(:exclude_graph))
      @resource_uri = Array(options.delete(:resource_uri))
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

    def_delegators :sparql, :query
    def_delegators :http, :get

    def availability
      @criteria[:availability] ||= Criteria::Availability.new(self)
    end

    def freshness
      @criteria[:freshness] ||= Criteria::Freshness.new(self)
    end

    def operation
      @criteria[:operation] ||= Criteria::Operation.new(self)
    end

    def usefulness
      @criteria[:usefulness] ||= Criteria::Usefulness.new(self)
    end

    def validity
      @criteria[:validity] ||= Criteria::Validity.new(self)
    end
  end
end
