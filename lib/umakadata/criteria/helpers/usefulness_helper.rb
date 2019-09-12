require 'umakadata/util/cacheable'
require 'umakadata/util/string'

module Umakadata
  module Criteria
    module Helpers
      module UsefulnessHelper
        include Cacheable
        include StringExt

        # @return [Umakadata::Activity]
        def graphs(**options)
          cache(:graphs, options) do
            if endpoint.graph_keyword_supported?
              endpoint
                .sparql
                .select(:g)
                .distinct
                .where(%i[s p o])
                .graph(:g)
                .execute
                .tap(&post_graphs)
            else
              endpoint.graph_keyword_support
            end
          end
        end

        # @param [Hash{Symbol => Object}] options
        # @option options [String] :graph
        # @return [Umakadata::Activity]
        def classes(**options)
          cache(:classes, options) do
            g = options[:graph]
            buffer = ['PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>']
            buffer << 'SELECT DISTINCT ?c WHERE {'
            buffer << "GRAPH <#{g}> {" if g
            buffer << '{ ?c a rdfs:Class . }'
            buffer << 'UNION { [] a ?c . }'
            buffer << 'UNION { [] rdfs:domain ?c . }'
            buffer << 'UNION { [] rdfs:range ?c . }'
            buffer << 'UNION { ?c rdfs:subClassOf [] . }'
            buffer << 'UNION { [] rdfs:subClassOf ?c . }'
            buffer << '}' if options[:graph]
            buffer << '} LIMIT 100'

            endpoint.sparql.query(buffer.join(' ')).tap(&post_classes(g))
          end
        end

        # @param [Hash{Symbol => Object}] options
        # @option options [String] :graph
        # @return [Umakadata::Activity]
        def classes_having_instance(**options)
          cache(:classes_having_instance, options) do
            g = options[:graph]
            endpoint
              .sparql
              .select(:c)
              .distinct
              .where([::RDF::BlankNode.new, ::RDF::RDFV.type, :c])
              .tap { |x| x.graph(g) if g }
              .execute
              .tap(&post_classes_having_instance(g))
          end
        end

        # @param [Array<String, #to_s>] classes
        # @param [Hash{Symbol => Object}] options
        # @option options [String] :graph
        # @return [Umakadata::Activity]
        def labels_of_classes(classes, **options)
          return nil if Array(classes).empty?

          g = options[:graph]
          endpoint
            .sparql
            .select(:c, :label)
            .distinct
            .where([:c, ::RDF::Vocab::RDFS.label, :label])
            .values(:c, *Array(classes))
            .tap { |x| x.graph(g) if g }
            .execute
            .tap(&post_labels_of_classes(g))
        end

        # @param [Hash{Symbol => Object}] options
        # @option options [String] :graph
        # @return [Umakadata::Activity]
        def properties(**options)
          cache(:properties, options) do
            g = options[:graph]
            endpoint
              .sparql
              .select(:p)
              .distinct
              .where(%i[s p o])
              .tap { |x| x.graph(g) if g }
              .execute
              .tap(&post_properties(g))
          end
        end

        BIND_FOR_EXTRACTING_PREFIX = 'IF(CONTAINS(STR(?p), "#"), REPLACE(STR(?p), "#[^#]*$", "#"), '\
                                     'REPLACE(STR(?p), "/[^/]*$", "/")) AS ?prefix'.freeze

        # @param [Hash{Symbol => Object}] options
        # @option options [String] :graph
        # @return [Umakadata::Activity]
        def vocabulary_prefixes(**options)
          cache(:vocabulary_prefixes, options) do
            g = options[:graph]
            endpoint
              .sparql
              .select(:prefix)
              .distinct
              .where(endpoint.sparql.select(:p).distinct.tap { |x| x.graph(g) if g }.where(%i[s p o]))
              .tap { |x| (x.options[:filters] ||= []) << ::SPARQL::Client::Query::Bind.new(BIND_FOR_EXTRACTING_PREFIX) }
              .execute
              .tap(&post_vocabulary_prefixes(g))
          end
        end

        # @return [Umakadata::Activity]
        def number_of_statements(**options)
          cache(:number_of_statements, options) do
            g = options[:graph]
            endpoint
              .sparql
              .select(count: { '*' => :count })
              .where(%i[s p o])
              .tap { |x| x.graph(g) if g }
              .execute
              .tap(&post_number_of_statements(g))
          end
        end

        private

        def excluded_graph?(graph)
          return Array(endpoint.exclude_graph).any?(&:blank?) if graph.nil?
          return true if (list = endpoint.exclude_graph).present? && Array(list).include?(graph)

          uri = RDF::URI(graph)
          return true unless uri.scheme&.match?(/https?/)
          return true if uri.host == 'www.w3.org' || uri.host == 'www.openlinksw.com' || uri.path&.match?(%r{/DAV/?})

          false
        end

        def post_graphs
          lambda do |activity|
            activity.type = Activity::Type::GRAPHS

            if (result = activity.result).is_a?(RDF::Query::Solutions)
              uri, not_uri = result.dup.bindings.fetch(:g, []).partition { |g| g.is_a?(RDF::URI) }
              exclude = uri.select { |g| excluded_graph?(g.value) }

              activity.result = uri - exclude # activity.result is no longer a RDF::Query::Solutions just an Array
              activity.comment = "#{pluralize(activity.result.count, 'graph')} found."
              exclude.each do |r|
                activity.comment += "\n- #{r.bindings[:g].value} is omitted."
              end
              not_uri.each do |r|
                activity.comment += "\n- #{r.bindings[:g].value} is not URI."
              end
            else
              activity.comment = 'No graphs found.'
            end
          end
        end

        def post_classes(graph = nil)
          lambda do |activity|
            activity.type = Activity::Type::CLASSES
            activity.comment = if activity.result.present?
                                 "#{pluralize(activity.result.count, 'class')} found"
                               else
                                 'No classes found'
                               end
            activity.comment << " on #{graph ? "graph <#{graph}>" : 'default graph'}."
          end
        end

        def post_classes_having_instance(graph = nil)
          lambda do |activity|
            activity.type = Activity::Type::CLASSES_HAVING_INSTANCE
            activity.comment = if activity.result.present?
                                 "#{pluralize(activity.result.count, 'class')} having instances found"
                               else
                                 'No classes having instances found'
                               end
            activity.comment << " on #{graph ? "graph <#{graph}>" : 'default graph'}."
          end
        end

        def post_labels_of_classes(graph = nil)
          lambda do |act|
            act.type = Activity::Type::LABELS_OF_CLASSES
            act.comment = if act.result.present?
                            "#{pluralize(act.result.count, 'label')} of classes found"
                          else
                            'No labels of classes found'
                          end
            act.comment << " on #{graph ? "graph <#{graph}>" : 'default graph'}."
          end
        end

        def post_properties(graph = nil)
          lambda do |act|
            act.type = Activity::Type::PROPERTIES
            act.comment = if act.result.present?
                            "#{pluralize(act.result.count, 'property')} found"
                          else
                            'No properties found'
                          end
            act.comment << " on #{graph ? "graph <#{graph}>" : 'default graph'}."
          end
        end

        def post_vocabulary_prefixes(graph = nil)
          lambda do |act|
            act.type = Activity::Type::VOCABULARY_PREFIXES
            act.comment = if act.result.present?
                            "#{pluralize(act.result.count, 'candidate')} for vocabulary prefix found"
                          else
                            'No candidates for vocabulary prefix found'
                          end
            act.comment << " on #{graph ? "graph <#{graph}>" : 'default graph'}."
          end
        end

        def post_number_of_statements(graph = nil)
          lambda do |act|
            act.type = Activity::Type::NUMBER_OF_STATEMENTS
            act.comment = if act.result.is_a?(RDF::Query::Solutions) && (c = act.result.map { |r| r.bindings[:count] }.first&.object)
                            "Count #{pluralize(c, 'triple')}"
                          else
                            'Failed to count the number of triples'
                          end
            act.comment << " on #{graph ? "graph <#{graph}>" : 'default graph'}."
          end
        end
      end
    end
  end
end
