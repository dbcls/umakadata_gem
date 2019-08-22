require 'umakadata/criteria/base'
require 'umakadata/criteria/helpers/usefulness_helper'

module Umakadata
  module Criteria
    class Usefulness < Base
      include Helpers::UsefulnessHelper

      MEASUREMENT_NAMES = {
        ontology: 'usefulness.ontology',
        metadata: 'usefulness.metadata',
        links_to_other_datasets: 'usefulness.links_to_other_datasets',
        data_entry: 'usefulness.data_entry',
        content_negotiation_supported?: 'usefulness.content_negotiation_supported',
        turtle_format_supported?: 'usefulness.turtle_format_supported'
      }.freeze

      #
      # @yield [measurement]
      # @yieldparam [Umakadata::Measurement]
      #
      # @return [true, false] true if the endpoint is alive
      def metadata
        activities = []
        activities << endpoint.graph_keyword_support

        if endpoint.graph_keyword_supported?
          activities << (grs = graphs)

          grs.result.map { |r| r.bindings[:g] }.each do |g|
            next if graph_in_exclude_list(grs, g)

            activities << classes_having_instance(graph: g)
            activities << labels_of_classes(classes(graph: g).result.map { |r| r.bindings[:c] }, graph: g)
          end
        end

        activities << classes_having_instance
        activities << labels_of_classes(classes.result.map { |r| r.bindings[:c] })

        n = (target = activities.filter { |a| a.result.is_a? Array }).size
        avg = target.inject(0) { |memo, t| memo + (t.result.size.positive? ? 0 : 100) } / n.to_f
        comment = if n.positive?
                    "Metadata score is #{avg}"
                  else
                    'There are no effective graphs.'
                  end

        measurement = Measurement.new(MEASUREMENT_NAMES[__method__], comment, activities)

        yield measurement if block_given?

        avg
      end

      def ontology
      end

      def links_to_other_datasets
      end

      def data_entry
      end

      def content_negotiation_supported?
      end

      def turtle_format_supported?
      end

      private

      def graph_in_exclude_list(activity, graph)
        uri = RDF::URI(graph)

        unless uri.scheme.match?(/https?/)
          activity.comment += "\n#{graph} is omitted because the URI does not start with http:// or https://."
          return true
        end

        if uri.host == 'www.w3.org' || uri.host == 'www.openlinksw.com' || uri.path == '/DAV'
          activity.comment += "\n#{graph} is omitted because the URI seems to be prepared by the triple store as default."
          return true
        end

        false
      end
    end
  end
end
