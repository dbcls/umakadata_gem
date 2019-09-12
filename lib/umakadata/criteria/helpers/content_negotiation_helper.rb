require 'umakadata/util/cacheable'

module Umakadata
  module Criteria
    module Helpers
      module ContentNegotiationHelper
        include Cacheable

        # @return [Umakadata::Measurement]
        def content_negotiate(type, measurement_name)
          m = Umakadata::Measurement.new

          begin
            activities = []

            endpoint.resource_uri.each do |p|
              activities.push(*check_content_negotiation(p, type))
            end

            m.name = measurement_name
            m.value = activities.any?(&negotiation_succeed?(type))
            m.comment = if m.value
                          "The endpoint supports content negotiation for #{type}"
                        else
                          "The endpoint does not support content negotiation for #{type}"
                        end
            m.activities = activities

            yield m if block_given?
          rescue StandardError => e
            m.comment = e.message
            m.exceptions = e
          ensure
            m
          end
        end

        # @param [ResourceURI] resource_uri
        # @param [String] content_type
        # @param [Hash] options
        # @return [Array<Umakadata::Activity>]
        def check_content_negotiation(resource_uri, content_type, **options)
          activities = []

          uri = resource_uri.uri.presence || begin
            activities << (r = retrieve_uri(resource_uri))
            r.result.is_a?(RDF::Query::Solutions) ? r.result&.first&.bindings&.dig(:s)&.value : nil
          end

          return activities if uri.blank?

          http_options = options.merge(response_parser: { strict: true })

          activities << (Umakadata::HTTP::Client.new(uri, **http_options).get(uri, Accept: content_type).tap do |act|
            return_type = act.response&.headers&.content_type
            act.type = ResourceURI.activity_type_for(content_type)
            act.comment = if (status = act.response.status) == 200
                            "#{uri} returns 'Content-Type: #{return_type}' for content negotiation "\
                            "by 'Accept: #{content_type}' in request header."
                          else
                            "#{uri} returns #{status || 'N/A'} #{act.response.reason_phrase || 'N/A'}"
                          end
          end)

          activities
        end

        private

        def retrieve_uri(resource_uri)
          return if (f = resource_uri.filter).blank?

          cache(:retrieve_uri, f) do
            endpoint
              .sparql
              .select(:s)
              .where(%i[s p o])
              .filter(f)
              .tap { |x| x.graph(:g) if endpoint.graph_keyword_supported? }
              .limit(1)
              .execute
              .tap do |act|
              act.type = Activity::Type::RETRIEVE_URI
              act.comment = if act.result.is_a?(RDF::Query::Solutions) && act.result.size.positive?
                              'An URI found by SPARQL query.'
                            else
                              'Failed to obtain URIs by SPARQL query.'
                            end
            end
          end
        end

        def negotiation_succeed?(type)
          lambda do |act|
            act.type.to_s.match?('content_negotiation_') &&
              act.response&.status == 200 &&
              act.response&.headers&.content_type.to_s.include?(type)
          end
        end
      end
    end
  end
end
