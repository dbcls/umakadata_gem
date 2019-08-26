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
              endpoint.sparql.select(:g).distinct.graph(:g).where(%i[s p o]).execute.tap do |act|
                act.type = Activity::Type::GRAPHS

                if (result = act.result).is_a?(Array)
                  exclude, act.result = result.partition { |r| excluded_graph?(r.bindings[:g].value) }

                  act.comment = "#{pluralize(act.result.count, 'graph')} found."
                  exclude.each do |r|
                    act.comment += "\n- #{r.bindings[:g].value} is omitted."
                  end
                else
                  act.comment = 'No graphs found.'
                end
              end
            else
              endpoint.graph_keyword_support
            end
          end
        end

        def excluded_graph?(graph)
          return true if graph.nil? && (list = endpoint.options[:exclude_graph]) && Array(list).any?(&:blank?)
          return true if (list = endpoint.options[:exclude_graph]) && Array(list).include?(graph)

          uri = RDF::URI(graph)
          return true unless uri.scheme.match?(/https?/)
          return true if uri.host == 'www.w3.org' || uri.host == 'www.openlinksw.com' || uri.path.match?(%r{/DAV/?})

          false
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

            endpoint.sparql.query(buffer.join(' ')).tap do |act|
              act.type = Activity::Type::CLASSES
              act.comment = if act.result.present?
                              "#{pluralize(act.result.count, 'class')} found"
                            else
                              'No classes found'
                            end
              act.comment << " on #{g ? "graph <#{g}>" : 'default graph'}."
            end
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
              .tap { |x| x.graph(g) if g }
              .where([::RDF::BlankNode.new, ::RDF::RDFV.type, :c])
              .execute
              .tap do |act|
              act.type = Activity::Type::CLASSES_HAVING_INSTANCE
              act.comment = if act.result.present?
                              "#{pluralize(act.result.count, 'class')} having instances found"
                            else
                              'No classes having instances found'
                            end
              act.comment << " on #{g ? "graph <#{g}>" : 'default graph'}."
            end
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
            .tap { |x| x.graph(g) if g }
            .where([:c, ::RDF::Vocab::RDFS.label, :label])
            .values(:c, *Array(classes))
            .execute
            .tap do |act|
            act.type = Activity::Type::LABELS_OF_CLASSES
            act.comment = if act.result.present?
                            "#{pluralize(act.result.count, 'label')} of classes found"
                          else
                            'No labels of classes found'
                          end
            act.comment << " on #{g ? "graph <#{g}>" : 'default graph'}."
          end
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
              .tap { |x| x.graph(g) if g }
              .where(%i[s p o])
              .execute
              .tap do |act|
              act.type = Activity::Type::PROPERTIES
              act.comment = if act.result.present?
                              "#{pluralize(act.result.count, 'property')} found"
                            else
                              'No properties found'
                            end
              act.comment << " on #{g ? "graph <#{g}>" : 'default graph'}."
            end
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
              .tap do |act|
              act.type = Activity::Type::VOCABULARY_PREFIXES
              act.comment = if act.result.present?
                              "#{pluralize(act.result.count, 'candidate')} for vocabulary prefix found"
                            else
                              'No candidates for vocabulary prefix found'
                            end
              act.comment << " on #{g ? "graph <#{g}>" : 'default graph'}."
            end
          end
        end

        # @return [Umakadata::Activity]
        def number_of_statements(**options)
          cache(:number_of_statements, options) do
            g = options[:graph]
            endpoint
              .sparql
              .select(count: { '*' => :count })
              .tap { |x| x.graph(g) if g }
              .where(%i[s p o])
              .execute
              .tap do |act|
              act.type = Activity::Type::NUMBER_OF_STATEMENTS
              act.comment = if act.result.is_a?(Array) && (c = act.result.map { |r| r.bindings[:count] }.first&.object)
                              "Count #{pluralize(c, 'triple')}"
                            else
                              'Failed to count the number of triples'
                            end
              act.comment << " on #{g ? "graph <#{g}>" : 'default graph'}."
            end
          end
        end
      end
    end
  end
end
