require 'umakadata/criteria/base'
require 'umakadata/criteria/helpers/usefulness_helper'

module Umakadata
  module Criteria
    class Usefulness < Base
      include Helpers::UsefulnessHelper

      MEASUREMENT_NAMES = {
        metadata: 'usefulness.metadata',
        ontology: 'usefulness.ontology',
        links_to_other_datasets: 'usefulness.links_to_other_datasets',
        data_entry: 'usefulness.data_entry',
        content_negotiation_supported?: 'usefulness.content_negotiation_supported',
        turtle_format_supported?: 'usefulness.turtle_format_supported'
      }.freeze

      #
      # @return [Umakadata::Measurement]
      def metadata
        activities = []
        activities << endpoint.graph_keyword_support

        if endpoint.graph_keyword_supported?
          activities << (grs = graphs)

          grs.result.map { |r| r.bindings[:g] }.each do |g|
            activities.push(*metadata_on_graph(g)) unless graph_in_exclude_list(grs, g)
          end
        end

        activities.push(*metadata_on_graph)

        Measurement.new do |m|
          m.name = MEASUREMENT_NAMES[__method__]
          m.value = (score = metadata_score(activities))
          m.comment = "Metadata score is #{score}"
          m.activities = activities
        end
      end

      #
      # @return [Umakadata::Measurement]
      def ontology
        activities = []
        activities << endpoint.graph_keyword_support

        if endpoint.graph_keyword_supported?
          activities << (grs = graphs)

          grs.result.map { |r| r.bindings[:g] }.each do |g|
            activities.push(*ontology_on_graph(g)) unless graph_in_exclude_list(grs, g)
          end
        end

        activities.push(*ontology_on_graph)

        Measurement.new do |m|
          score, in_lov = ontology_score(activities)
          m.name = MEASUREMENT_NAMES[__method__]
          m.value = score
          m.comment = "Metadata score is #{score} (#{pluralize(in_lov, 'prefix')} found in LinkedOpenVocabulary.)"
          m.activities = activities
        end
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

      def metadata_score(activities)
        graphs = activities.find { |act| act.type == Activity::Type::GRAPHS }

        return 0 unless graphs.result.is_a?(Array)

        sum = 0
        activities.filter { |act| act.type == Activity::Type::CLASSES_HAVING_INSTANCE }.each do |act|
          sum += 50 if act.result.is_a?(Array) && act.result.size.positive?
        end
        activities.filter { |act| act.type == Activity::Type::LABELS_OF_CLASSES }.each do |act|
          sum += 50 if act.result.is_a?(Array) && act.result.size.positive?
        end

        sum.to_f / (graphs.result.size + 1)
      end

      def ontology_score(activities)
        prefixes = activities
                     .filter { |act| act.type == Activity::Type::VOCABULARY_PREFIXES }
                     .map { |act| act.result.is_a?(Array) ? act.result.map { |x| x.bindings[:prefix].value } : [] }
                     .flatten
                     .uniq
                     .reject { |x| VocabularyPrefix.exclude_patterns.find { |p| x.match?(p) } }

        noe = prefixes.inject(0) { |m, p| m + (LinkedOpenVocabulary.all.find { |x| p.start_with?(x) } ? 1 : 0) }
        nolov = prefixes.inject(0) { |m, p| m + (VocabularyPrefix.all.find { |x| p.start_with?(x) } ? 1 : 0) }

        [50.0 * (nolov.size.to_f + noe.size.to_f) / prefixes.size, nolov.size]
      end

      def metadata_on_graph(name = nil)
        options = { graph: name }.compact
        activities = []
        activities << classes_having_instance(options)
        activities << labels_of_classes(classes(options).result.map { |r| r.bindings[:c] }, options)
        activities
      end

      def ontology_on_graph(name = nil)
        options = { graph: name }.compact
        [vocabulary_prefixes(options)]
      end

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
