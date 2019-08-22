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
                act.comment = if act.result.present?
                                "#{pluralize(act.result.count, 'graph')} found."
                              else
                                'No graphs found.'
                              end
              end
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
            buffer = ['PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>']
            buffer << 'SELECT DISTINCT ?c WHERE {'
            buffer << "GRAPH <#{options[:graph]}> {" if options[:graph]
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
                              "#{pluralize(act.result.count, 'class')} found."
                            else
                              'No classes found.'
                            end
            end
          end
        end

        # @param [Hash{Symbol => Object}] options
        # @option options [String] :graph
        # @return [Umakadata::Activity]
        def classes_having_instance(**options)
          cache(:classes_having_instance, options) do
            endpoint
              .sparql
              .select(:c)
              .distinct
              .tap { |x| x.graph(options[:graph]) if options[:graph] }
              .where([::RDF::BlankNode.new, ::RDF::RDFV.type, :c])
              .execute
              .tap do |act|
              act.type = Activity::Type::CLASSES_HAVING_INSTANCE
              act.comment = if act.result.present?
                              "#{pluralize(act.result.count, 'instance')} found."
                            else
                              'No instances found.'
                            end
            end
          end
        end

        # @param [Array<String, #to_s>] classes
        # @param [Hash{Symbol => Object}] options
        # @option options [String] :graph
        # @return [Umakadata::Activity]
        def labels_of_classes(classes, **options)
          if Array(classes).empty?
            return Activity.new do |act|
              act.result = []
              act.type = Activity::Type::LABELS_OF_CLASSES
              act.comment = 'Classes empty.'
            end
          end

          endpoint
            .sparql
            .select(:c, :label)
            .distinct
            .tap { |x| x.graph(options[:graph]) if options[:graph] }
            .where([:c, ::RDF::Vocab::RDFS.label, :label])
            .values(:c, *Array(classes))
            .execute
            .tap do |act|
            act.type = Activity::Type::LABELS_OF_CLASSES
            act.comment = if act.result.present?
                            "#{pluralize(act.result.count, 'instance')} found."
                          else
                            'No instances found.'
                          end
          end
        end

        # @return [Umakadata::Activity]
        def number_of_statements(**options)
          cache(:number_of_statements, options) do
            endpoint
              .sparql
              .select(count: { '*' => :count })
              .where(%i[s p o])
              .tap { |x| x.graph(:g) if options[:graph] }
              .execute
              .tap do |act|
              act.type = Activity::Type::NUMBER_OF_STATEMENTS
              act.comment = if act.result.is_a?(Array) && (c = act.result.map { |r| r.bindings[:count] }.first)
                              "The number of statements is #{c}."
                            else
                              'Failed to count the number of statements.'
                            end
            end
          end
        end
      end
    end
  end
end
