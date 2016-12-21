require 'json'
require 'sparql/client'
require 'umakadata/error_helper'
require 'umakadata/http_helper'
require 'umakadata/sparql_helper'
require 'umakadata/logging/log'

module Umakadata
  module Criteria
    module SPARQLWithoutGraph
      module Metadata

        REGEXP = /<title>(.*)<\/title>/

        include Umakadata::ErrorHelper

        def metadata(uri, logger: nil)
          classes_log = Umakadata::Logging::Log.new
          classes = self.obtain_classes(uri, logger: classes_log)

          labels_log = Umakadata::Logging::Log.new
          labels_search_log = Umakadata::Logging::Log.new
          labels_log.push labels_search_log
          labels = list_of_labels_of_classes(uri, classes, logger: labels_search_log)
          labels_search_log.result = "#{labels.size} lables are found"

          datatypes_log = Umakadata::Logging::Log.new
          datatypes_search_log = Umakadata::Logging::Log.new
          datatypes_log.push datatypes_search_log
          datatypes = self.list_of_datatypes(uri, logger: datatypes_search_log)
          datatypes_search_log.result = "#{datatypes.size} datatypes are found"

          properties_log = Umakadata::Logging::Log.new
          properties_search_log = Umakadata::Logging::Log.new
          properties_log.push properties_search_log
          properties = self.list_of_properties(uri, logger: properties_search_log)
          properties_search_log.result = "#{properties.size} properties are found"

          metadata = {
            classes: classes,
            labels: labels,
            datatypes: datatypes,
            properties: properties,
            classes_log: classes_log,
            labels_log: labels_log,
            datatypes_log: datatypes_log,
            properties_log: properties_log
          }
        end

        def score_metadata(metadata, logger: nil)
          score_proc = lambda do |data|
            graph_log = Umakadata::Logging::Log.new
            logger.push graph_log unless logger.nil?

            total_score = 0
            score = data[:classes].empty? ? 0 : 25
            unless logger.nil?
              classes_log = data[:classes_log]
              graph_log.push classes_log
              classes_log.result = "Classes score is #{score}"
            end
            total_score += score

            score = data[:labels].empty? ? 0 : 25
            total_score += score
            unless logger.nil?
              labels_log = data[:labels_log]
              graph_log.push labels_log
              labels_log.result = "Labels score is #{score}"
            end

            score = data[:datatypes].empty? ? 0 : 25
            total_score += score
            unless logger.nil?
              datatypes_log = data[:datatypes_log]
              graph_log.push datatypes_log
              datatypes_log.result = "Datatypes score is #{score}"
            end

            score = data[:properties].empty? ? 0 : 25
            total_score += score
            unless logger.nil?
              properties_log = data[:properties_log]
              graph_log.push properties_log
              properties_log.result = "Properties score is #{score}"
            end

            graph_log.result = "Score is #{total_score}"
            total_score
          end
          metadata_score = self.score_without_graph(metadata, score_proc)
          logger.result = "Metadata score is #{metadata_score}" unless logger.nil?
          metadata_score
        end

        def score_ontologies_for_endpoints(ontologies, rdf_prefixes, logger: nil)
          log = Umakadata::Logging::Log.new
          logger.push log unless logger.nil?
          used_ontologies = 0
          ontologies.each do |ontology|
            include_ontology_log = Umakadata::Logging::Log.new
            log.push include_ontology_log
            if rdf_prefixes.include?(ontology)
              used_ontologies += 1
              include_ontology_log.result = "#{ontology} is used in other endpoints"
            else
              include_ontology_log.result = "#{ontology} is not used in other endpoints"
            end
          end
          score = ((used_ontologies.to_f / ontologies.count.to_f) * 100) / 2
          total_score = score < 0 ? 0 : score
          log.result = "#{used_ontologies} ontologies are used in other endpoints"
          logger.result = "Ontology score (among other endpoints) is #{total_score}" unless logger.nil?
          total_score
        end

        def score_ontologies_for_LOV(ontologies, lov, logger: nil)
          log = Umakadata::Logging::Log.new
          logger.push log unless logger.nil?
          used_ontologies = 0
          ontologies.each do |ontology|
            includes_ontology_log = Umakadata::Logging::Log.new
            log.push includes_ontology_log
            if lov.include?(ontology)
              used_ontologies += 1
              includes_ontology_log.result = "#{ontology} is listed in LOV"
            else
              includes_ontology_log.result = "#{ontology} is not listed in LOV"
            end
          end
          score = ((used_ontologies.to_f / ontologies.count.to_f) * 100) / 2
          log.result = "#{used_ontologies} / #{ontologies.count} ontologies match vocabularies on LOV"
          logger.result = "Ontology score (Linked Open Vocabularies) is #{score}" unless logger.nil?
          score < 0 ? 0 : score
        end

        def list_ontologies(metadata, logger: nil)
          properties_log = metadata[:properties_log]
          logger.push properties_log unless logger.nil?
          properties = metadata[:properties]
          if properties.empty?
            properties_log.result = "0 ontologies are found"
            logger.result = "0 commmon ontologies are found"
            return Array.new
          end

          ontologies = self.ontologies(properties)
          properties_log.result = "#{ontologies.count} ontologies are found"
          logger.result = "#{ontologies.count} commmon ontologies are found" unless logger.nil?
          ontologies
        end

        def list_ontologies_in_LOV(metadata, logger: nil)
          return Umakadata::LinkedOpenVocabularies.instance.get(logger: logger)
        end

        def ontologies(properties)
          ontologies = []
          properties.each do |uri|
            uri = uri.to_s
            if uri.include?('#')
              ontologies.push uri.split('#')[0]
            else
              ontologies.push /^(.*\/).*?$/.match(uri)[1]
            end
          end
          return ontologies.uniq
        end

        def score_without_graph(metadata, score_proc)
          return 0 if metadata.nil? || metadata.empty?
          return score_proc.call(metadata)
        end

        def obtain_classes(uri, logger: nil)
          classes_log = Umakadata::Logging::Log.new
          logger.push classes_log unless logger.nil?
          classes = self.list_of_classes(uri, logger: classes_log)
          classes_log.result = "#{classes.size} classes are found"

          classes_having_instances_log = Umakadata::Logging::Log.new
          logger.push classes_having_instances_log unless logger.nil?
          classes_having_instances = self.list_of_classes_having_instances(uri, logger: classes_having_instances_log)
          classes_having_instances_log.result = "#{classes_having_instances.size} classes having instances are found"

          classes += classes_having_instances
          classes.uniq!
          return classes
        end

        def list_of_classes(uri, logger: nil)
          query = <<-SPARQL
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
SELECT DISTINCT ?c
WHERE {
  { ?c rdf:type rdfs:Class. }
  UNION
  { [] rdf:type ?c. }
  UNION
  { [] rdfs:domain ?c. }
  UNION
  { [] rdfs:range ?c. }
  UNION
  { ?c rdfs:subclassOf []. }
  UNION
  { [] rdfs:subclassOf ?c. }
}
LIMIT 100
SPARQL
          message = "An error occurred in retrieving a list of classes"
          results = metadata_query(uri, query, message, logger: logger)

          return [] if results.nil?
          results.map { |solution| solution[:c] }
        end

        def list_of_classes_having_instances(uri, logger: nil)
          query = <<-SPARQL
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
SELECT DISTINCT ?c
WHERE { [] rdf:type ?c. }
SPARQL
          message = "An error occurred in retrieving the classes having instances"
          results = metadata_query(uri, query, message, logger: logger)

          return [] if results.nil?
          results.map { |solution| solution[:c] }
        end

        def list_of_labels_of_classes(uri, classes, logger: nil)
          query = <<-SPARQL
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
SELECT DISTINCT ?c ?label
WHERE {
      ?c rdfs:label ?label.
      filter (
        ?c IN (<#{classes.join('>,<')}>)
      )
}
SPARQL
          message = "An error occurred in retrieving a list of labels"
          results = metadata_query(uri, query, message, logger: logger)

          return [] unless results.is_a?(RDF::Query::Solutions)
          results.map { |solution| solution[:label] }
        end

        def list_of_properties(uri, logger: nil)
          query = <<-SPARQL
SELECT DISTINCT ?p
WHERE{
  ?s ?p ?o.
}
SPARQL
          message = "An error occurred in retrieving a list of properties"
          results = metadata_query(uri, query, message, logger: logger)

          return [] if results.nil?
          results.map { |solution| solution[:p] }
        end

        def list_of_datatypes(uri, logger: nil)
          query = <<-SPARQL
SELECT DISTINCT (datatype(?o) AS ?ldt)
WHERE{
  [] ?p ?o.
  FILTER(isLiteral(?o))
}
SPARQL
          message = "An error occurred in retrieving a list of datatypes"
          results = metadata_query(uri, query, message, logger: logger)

          return [] if results.nil?
          results.map { |solution| solution[:ldt] }
        end

        def query_metadata(client, query)
          begin
            results = client.query(query)
            if results.nil?
              client.response(query)
              set_error('Endpoint URI is different from actual URI in executing query')
              return nil
            end
          rescue SPARQL::Client::MalformedQuery => e
            set_error("Query: #{query}, Error: #{e.message}")
            return nil
          rescue SPARQL::Client::ClientError, SPARQL::Client::ServerError => e
            message = e.message.scan(REGEXP)[0]
            if message.nil?
              result = e.message.scan(/"datatype":\s"(.*\n)/)[0]
              if result.nil?
                message = ''
              else
                message = result[0].chomp
              end
            end
            set_error("Query: #{query}, Error: #{message}")
            return nil
          rescue => e
            set_error("Query: #{query}, Error: #{e.to_s}")
            return nil
          end

          return results
        end

        def metadata_query(uri, sparql_query, message, logger: nil)
          results = nil
          [:post, :get].each do |method|
            request_log = Umakadata::Logging::Log.new
            logger.push request_log unless logger.nil?
            results = Umakadata::SparqlHelper.query(uri, sparql_query, logger: request_log, options: {method: method})
            unless results.nil?
              request_log.result = "200 HTTP response"
              return results
            end
            request_log.result = message
          end
          results
        end

      end
    end
  end
end
