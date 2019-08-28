module Umakadata
  class ResourceURI
    module NegotiationTypes
      TURTLE = 'text/turtle'.freeze
      RDFXML = 'application/rdf+xml'.freeze
      HTML = 'text/html'.freeze
    end

    class << self
      include NegotiationTypes

      def activity_type_for(negotiation_type)
        case negotiation_type
        when HTML
          Activity::Type::CONTENT_NEGOTIATION_HTML
        when TURTLE
          Activity::Type::CONTENT_NEGOTIATION_TURTLE
        when RDFXML
          Activity::Type::CONTENT_NEGOTIATION_RDFXML
        else
          Activity::Type::UNKNOWN
        end
      end
    end

    attr_reader :uri
    attr_reader :as_regex
    attr_reader :allow
    attr_reader :deny
    attr_reader :case_insensitive

    def initialize(attributes = {})
      @uri = attributes[:uri]
      @as_regex = attributes.fetch(:as_regex, false)
      @allow = attributes[:allow]
      @deny = attributes[:deny]
      @case_insensitive = attributes.fetch(:case_insensitive, false)
    end

    def filter
      return if @uri.present?

      @as_regex ? regex : str_starts
    end

    private

    def regex
      conditions = []
      conditions << %[REGEX(STR(?s), "^#{@allow}"#{', "i"' if @case_insensitive})] if @allow.present?
      conditions << %[!REGEX(STR(?s), "^#{@deny}"#{', "i"' if @case_insensitive})] if @deny.present?
      conditions.join(' && ').presence
    end

    def str_starts
      conditions = []
      conditions << %[STRSTARTS(STR(?s), "#{@allow}")] if @allow.present?
      conditions << %[!STRSTARTS(STR(?s), "#{@deny}")] if @deny.present?
      conditions.join(' && ').presence
    end
  end
end
