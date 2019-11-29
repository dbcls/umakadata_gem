require 'umakadata/criteria/base'
require 'umakadata/criteria/helpers/content_negotiation_helper'
require 'umakadata/criteria/helpers/usefulness_helper'

module Umakadata
  module Criteria
    class Usefulness < Base
      include Helpers::ContentNegotiationHelper
      include Helpers::UsefulnessHelper

      MEASUREMENT_NAMES = {
        metadata: 'usefulness.metadata',
        ontology: 'usefulness.ontology',
        links_to_other_datasets: 'usefulness.links_to_other_datasets',
        data_entry: 'usefulness.data_entry',
        support_html_format: 'usefulness.support_html_format',
        support_rdfxml_format: 'usefulness.support_rdfxml_format',
        support_turtle_format: 'usefulness.support_turtle_format'
      }.freeze

      def measurements
        MEASUREMENT_NAMES.keys.map { |x| method(x) }
      end

      #
      # @return [Umakadata::Measurement]
      def metadata
        Umakadata::Measurement.new(name: MEASUREMENT_NAMES[__method__]).safe do |m|
          activities = []

          if endpoint.graph_keyword_supported?
            activities << (grs = graphs)

            grs.result.each do |g|
              activities.push(*metadata_on_graph(g)) unless excluded_graph?(g)
            end
          end

          activities.push(*metadata_on_graph) unless excluded_graph?(nil)

          m.value = (score = metadata_score(activities))
          m.comment = "Metadata score is #{score.round(1)}"
          m.activities = activities
        end
      end

      #
      # @return [Umakadata::Measurement]
      def ontology
        Umakadata::Measurement.new(name: MEASUREMENT_NAMES[__method__]).safe do |m|
          activities = []

          if endpoint.graph_keyword_supported?
            activities << (grs = graphs)

            grs.result.each do |g|
              activities.push(*ontology_on_graph(g)) unless excluded_graph?(g)
            end
          end

          activities.push(*ontology_on_graph) unless excluded_graph?(nil)

          score, noe, nolov = ontology_score(activities)

          m.value = score
          m.comment = "Ontology score is #{score.round(1)}.\n"\
                      "- #{pluralize(nolov, 'prefix')} found in Linked Open Vocabulary.\n"\
                      "- #{pluralize(noe, 'prefix')} found in other endpoint."
          m.activities = activities
        end
      end

      #
      # @return [Umakadata::Measurement]
      def links_to_other_datasets
        Umakadata::Measurement.new(name: MEASUREMENT_NAMES[__method__]).safe do |m|
          m.value = endpoint.void.link_sets.presence&.join("\n")
        end
      end

      #
      # @return [Umakadata::Measurement]
      def data_entry
        Umakadata::Measurement.new(name: MEASUREMENT_NAMES[__method__]).safe do |m|
          activities = []

          if (v = endpoint.void&.triples)&.positive?
            m.value = v
            m.comment = "Count #{pluralize(v, 'triple')} from VoID."
          else
            if endpoint.graph_keyword_supported?
              activities << (grs = graphs)

              grs.result.each do |g|
                activities << number_of_statements(graph: g) unless excluded_graph?(g)
              end
            end

            activities << number_of_statements unless excluded_graph?(nil)

            m.value = activities
                        .filter { |act| act.type == Activity::Type::NUMBER_OF_STATEMENTS && act.result.is_a?(::RDF::Query::Solutions) }
                        .inject(0) { |memo, act| memo + (act.result.map { |r| r.bindings[:count] }.first&.object || 0) }
            m.comment = "Count #{pluralize(m.value, 'triple')}."
          end

          m.activities = activities
        end
      end

      def support_html_format
        content_negotiate(ResourceURI::NegotiationTypes::HTML, MEASUREMENT_NAMES[__method__])
      end

      def support_rdfxml_format
        content_negotiate(ResourceURI::NegotiationTypes::RDFXML, MEASUREMENT_NAMES[__method__])
      end

      def support_turtle_format
        content_negotiate(ResourceURI::NegotiationTypes::TURTLE, MEASUREMENT_NAMES[__method__])
      end

      private

      def metadata_score(activities)
        graphs = activities.find { |act| act.type == Activity::Type::GRAPHS }

        return 0 if graphs && !graphs.result.is_a?(Array)

        sum = 0
        activities.filter { |act| act.type == Activity::Type::CLASSES_HAVING_INSTANCE }.each do |act|
          sum += 50 if act.result.is_a?(::RDF::Query::Solutions) && act.result.size.positive?
        end
        activities.filter { |act| act.type == Activity::Type::LABELS_OF_CLASSES }.each do |act|
          sum += 50 if act.result.is_a?(::RDF::Query::Solutions) && act.result.size.positive?
        end

        ngraphs = (graphs ? graphs.result.size : 0) + (excluded_graph?(nil) ? 0 : 1)

        ngraphs.positive? ? sum.to_f / ngraphs : 0
      end

      def ontology_score(activities)
        prefixes = activities
                     .filter { |act| act.type == Activity::Type::VOCABULARY_PREFIXES }
                     .map { |act| (r = act.result).is_a?(::RDF::Query::Solutions) ? r.map { |x| x.bindings[:prefix].value } : [] }
                     .flatten
                     .uniq
                     .reject { |x| VocabularyPrefix.exclude_patterns.find { |p| x.match?(p) } }

        endpoint.vocabulary_prefix = prefixes

        noe = prefixes.inject(0) { |m, p| m + (endpoint.vocabulary_prefix_others.find { |x| p.start_with?(x) } ? 1 : 0) }
        nolov = prefixes.inject(0) { |m, p| m + (LinkedOpenVocabulary.all.find { |x| p.start_with?(x) } ? 1 : 0) }

        [prefixes.size.positive? ? 50.0 * (nolov.to_f + noe.to_f) / prefixes.size : 0, noe, nolov]
      end

      def metadata_on_graph(name = nil)
        options = { graph: name }.compact
        activities = []
        activities << classes_having_instance(options)
        activities << (classes = classes(options))
        activities << labels_of_classes(classes.result.map { |r| r.bindings[:c] }, options) if classes
        activities.compact
      end

      def ontology_on_graph(name = nil)
        options = { graph: name }.compact
        [vocabulary_prefixes(options)]
      end
    end
  end
end
