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
            activities.push(*metadata_on_graph(g)) unless excluded_graph?(g)
          end
        end

        activities.push(*metadata_on_graph) unless excluded_graph?(nil)

        Measurement.new do |m|
          m.name = MEASUREMENT_NAMES[__method__]
          m.value = (score = metadata_score(activities))
          m.comment = "Metadata score is #{score.round(1)}"
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
            activities.push(*ontology_on_graph(g)) unless excluded_graph?(g)
          end
        end

        activities.push(*ontology_on_graph) unless excluded_graph?(nil)

        Measurement.new do |m|
          score, noe, nolov = ontology_score(activities)
          m.name = MEASUREMENT_NAMES[__method__]
          m.value = score
          m.comment = "Ontology score is #{score.round(1)}.\n"\
                      "- #{pluralize(nolov, 'prefix')} found in Linked Open Vocabulary.\n"\
                      "- #{pluralize(noe, 'prefix')} found in other endpoint."
          m.activities = activities
        end
      end

      def links_to_other_datasets
      end

      def data_entry
        activities = []

        count = if (v = endpoint.void).triples.present?
                  activities << v

                  v.triples
                else
                  activities << endpoint.graph_keyword_support

                  if endpoint.graph_keyword_supported?
                    activities << (grs = graphs)

                    grs.result.map { |r| r.bindings[:g] }.each do |g|
                      activities << number_of_statements(graph: g) unless excluded_graph?(g)
                    end
                  end

                  activities << number_of_statements unless excluded_graph?(nil)

                  activities
                    .filter { |act| act.type == Activity::Type::NUMBER_OF_STATEMENTS && act.result.is_a?(Array) }
                    .inject(0) { |memo, act| memo + (act.result.map { |r| r.bindings[:count] }.first&.object || 0) }
                end

        Measurement.new do |m|
          m.name = MEASUREMENT_NAMES[__method__]
          m.value = count
          m.comment = "Count #{pluralize(count, 'triple')}."
          m.activities = activities
        end
      end

      def content_negotiation_supported?
      end

      def turtle_format_supported?
      end

      private

      def metadata_score(activities)
        graphs = activities.find { |act| act.type == Activity::Type::GRAPHS }

        return 0 unless graphs&.result&.is_a?(Array)

        sum = 0
        activities.filter { |act| act.type == Activity::Type::CLASSES_HAVING_INSTANCE }.each do |act|
          sum += 50 if act.result.is_a?(Array) && act.result.size.positive?
        end
        activities.filter { |act| act.type == Activity::Type::LABELS_OF_CLASSES }.each do |act|
          sum += 50 if act.result.is_a?(Array) && act.result.size.positive?
        end

        (n = graphs.result.size + (excluded_graph?(nil) ? 0 : 1)).positive? ? sum.to_f / n : 0
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

        [prefixes.size.positive? ? 50.0 * (nolov.size.to_f + noe.size.to_f) / prefixes.size : 0, noe.size, nolov.size]
      end

      def metadata_on_graph(name = nil)
        options = { graph: name }.compact
        activities = []
        activities << classes_having_instance(options)
        activities << labels_of_classes(classes(options).result.map { |r| r.bindings[:c] }, options)
        activities.compact
      end

      def ontology_on_graph(name = nil)
        options = { graph: name }.compact
        [vocabulary_prefixes(options)]
      end
    end
  end
end
