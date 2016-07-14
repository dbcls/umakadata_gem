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

        COMMON_ONTOLOGIES = [
          'http://www.w3.org/2000/01/rdf-schema',
          'http://www.w3.org/1999/02/22-rdf-syntax-ns',
          'http://www.socrata.com/rdf/terms',
          'http://www.w3.org/2003/01/geo/wgs84_pos',
          'http://xmlns.com/foaf/0.1/',
          'http://www.w3.org/2002/07/owl',
          'http://purl.org/dc/elements/1.1/',
          'http://purl.org/dc/terms/',
          'http://www.w3.org/2000/10/swap/pim/usps',
          'http://dublincore.org/documents/dcmi-box/',
          'http://www.territorio.provincia.tn.it/geodati/ontology/',
          'http://www.w3.org/2004/02/skos/core',
        ]

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

        def score_ontologies(metadata, logger: nil)
          score_proc = lambda do |data|
            if data[:properties].empty?
              score = 0
              properties_log = data[:properties_log]
              logger.push properties_log
              properties_log.result = '0 ontologies are found'
              return score
            end

            graph_log = Umakadata::Logging::Log.new
            logger.push graph_log unless logger.nil?
            ontologies = self.ontologies(data[:properties])
            commons = ontologies.count{ |ontology| COMMON_ONTOLOGIES.include?(ontology) }
            score = commons.to_f / ontologies.count.to_f * 100.0

            properties_log = data[:properties_log]
            graph_log.push properties_log
            properties_log.result = "#{ontologies.count} ontologies are found and #{commons} common ontologies has been used" unless logger.nil?
            graph_log.result = "Score is #{score}"
            return score
          end
          ontology_score = self.score_without_graph(metadata, score_proc)
          logger.result = "Ontology score is #{ontology_score}" unless logger.nil?
          ontology_score
        end

        def score_vocabularies(metadata, logger: nil)
          score_proc = lambda do |data|
            count = data[:properties].count
            properties_log = data[:properties_log]
            logger.push properties_log
            properties_log.result = "Score is #{count}"
            return count
          end

          vocabulary_score = self.score_without_graph(metadata, score_proc)
          logger.result = "Vocabulary score is #{vocabulary_score}" unless logger.nil?
          vocabulary_score
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

          results = Umakadata::SparqlHelper.query(uri, query, logger: logger)
          return [] if results.nil?
          results.map { |solution| solution[:c] }
        end

        def list_of_classes_having_instances(uri, logger: nil)
          query = <<-SPARQL
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
SELECT DISTINCT ?c
WHERE { [] rdf:type ?c. }
SPARQL

          results = Umakadata::SparqlHelper.query(uri, query, logger: logger)
          return [] if results.nil?
          results.map { |solution| solution[:c] }
        end

        def list_of_labels_of_a_class(client, graph, cls)
          query = <<-SPARQL
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
SELECT DISTINCT ?label
FROM <#{graph}>
WHERE{ <#{cls}> rdfs:label ?label. }
SPARQL
          results = self.query_metadata(client, query)
          return [] if results.nil?
          results.map { |solution| solution[:label] }
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

          results = Umakadata::SparqlHelper.query(uri, query, logger: logger)
          return [] if results.nil?
          results.map { |solution| solution[:label] }
        end

        def number_of_instances_of_class_on_a_graph(client, graph, cls)
          query = <<-SPARQL
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
SELECT (count(DISTINCT ?i)  AS ?num)
  FROM <#{graph}>
WHERE{
  { ?i rdf:type <#{cls}>. }
  UNION
  { [] ?p ?i. ?p rdfs:range <#{cls}>. }
  UNION
  { ?i ?p []. ?p rdfs:domain <#{cls}>. }
}
SPARQL

          results = self.query_metadata(client, query)
          return 0 if results.nil?
          return results[0][:num]
        end

        def list_of_properties(uri, logger: nil)
          query = <<-SPARQL
SELECT DISTINCT ?p
WHERE{
  ?s ?p ?o.
}
SPARQL

          results = Umakadata::SparqlHelper.query(uri, query, logger: logger)
          return [] if results.nil?
          results.map { |solution| solution[:p] }
        end

        def list_of_domain_classes_of_property_on_graph(client, graph, property)
          query = <<-SPARQL
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
SELECT DISTINCT ?d
FROM <#{graph}>
WHERE {
  <#{property}> rdfs:domain ?d.
}
SPARQL
          results = self.query_metadata(client, query)
          return [] if results.nil?
          results.map { |solution| solution[:d] }
        end

        def list_of_range_classes_of_property_on_graph(client, graph, property)
          query = <<-SPARQL
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
SELECT DISTINCT ?r
FROM <#{graph}>
WHERE{
  <#{property}> rdfs:range ?r.
}
SPARQL
          results = self.query_metadata(client, query)
          return [] if results.nil?
          results.map { |solution| solution[:d] }
        end

        def list_of_class_class_relationships(client, graph, property)
          query = <<-SPARQL
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
SELECT DISTINCT ?d ?r
FROM <#{graph}>
WHERE{
        ?i <#{property}> ?o.
        OPTIONAL{ ?i rdf:type ?d.}
        OPTIONAL{ ?o rdf:type ?r.}
}
SPARQL
          results = self.query_metadata(client, query)
          return [] if results.nil?
          results.map { |solution| [ solution[:d], solution[:r] ] }
        end

        def list_of_class_datatype_relationships(client, graph, property)
          query = <<-SPARQL
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
SELECT DISTINCT ?d (datatype(?o) AS ?ldt)
FROM <#{graph}>
WHERE{
    ?i <#{property}> ?o.
    OPTIONAL{ ?i rdf:type ?d.}
    FILTER(isLiteral(?o))
}
SPARQL
          results = self.query_metadata(client, query)
          return [] if results.nil?
          results.map { |solution| [ solution[:d], solution[:ldt] ] }
        end

        def number_of_elements1(client, graph, property, domain, range)
          query = <<-SPARQL
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
SELECT (count(?i) AS ?numTriples) (count(DISTINCT ?i) AS ?numDomIns) (count(DISTINCT ?o) AS ?numRanIns)
FROM <#{graph}>
WHERE {
  SELECT DISTINCT ?i ?o WHERE {
    ?i <#{property}> ?o.
    ?i rdf:type <#{domain}>.
    ?o rdf:type <#{range}>.
  }
}
SPARQL
          results = self.query_metadata(client, query)
          return nil if results.nil?
          return [ results[0][:numTriples], results[0][:numDomIns], results[0][:numRanIns] ]
        end

        def number_of_elements2(client, graph, property, datatype)
          query = <<-SPARQL
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
SELECT (count(?i) AS ?numTriples) (count(DISTINCT ?i) AS ?numDomIns) (count(DISTINCT ?o) AS ?numRanIns)
        FROM <#{graph}>
WHERE{
  SELECT DISTINCT ?i ?o WHERE{
    ?i <#{property}> ?o.
    ?i rdf:type ?d.
    FILTER( datatype(?o) = <#{datatype}> )
  }
}
SPARQL
          results = self.query_metadata(client, query)
          return nil if results.nil?
          return [ results[0][:numTriples], results[0][:numDomIns], results[0][:numRanIns] ]
        end

        def number_of_elements3(client, graph, property)
query = <<-SPARQL
SELECT (count(?i) AS ?numTriples) (count(DISTINCT ?i) AS ?numDomIns) (count(DISTINCT ?o) AS ?numRanIns)
FROM <#{graph}>
WHERE{
   ?i <#{property}> ?o.
}
SPARQL
          results = self.query_metadata(client, query)
          return nil if results.nil?
          return [ results[0][:numTriples], results[0][:numDomIns], results[0][:numRanIns] ]
        end

        def number_of_elements4(client, graph, property)
          query = <<-SPARQL
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
SELECT (count(DISTINCT ?i) AS ?numDomIns) (count(?i) AS ?numTriplesWithDom)
FROM <#{graph}>
WHERE {
  SELECT DISTINCT ?i ?o
  WHERE{
    ?i <#{property}> ?o.
    ?i rdf:type ?d.
  }
}
SPARQL
          results = self.query_metadata(client, query)
          return nil if results.nil?
          return [ results[0][:numDomIns], results[0][:numTriplesWithDom] ]
        end

        def number_of_elements5(client, graph, property)
          query = <<-SPARQL
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
SELECT (count(DISTINCT ?o) AS ?numRanIns) (count(?o) AS ?numTriplesWithRan)
FROM <#{graph}>
WHERE {
  SELECT DISTINCT ?i ?o
  WHERE{
    ?i <#{property}> ?o.
    ?o rdf:type ?r.
  }
}
SPARQL
          results = self.query_metadata(client, query)
          return nil if results.nil?
          return [ results[0][:numRanIns], results[0][:numTriplesWithRan] ]
        end

        def number_of_elements6(client, graph, property)
          query = <<-SPARQL
SELECT (count(DISTINCT ?o) AS ?numRanIns) (count(?o) AS ?numTriplesWithRan)
FROM <#{graph}>
WHERE {
  SELECT DISTINCT ?i ?o
  WHERE{
    ?i <#{property}> ?o.
    FILTER(isLiteral(?o))
  }
}
SPARQL
          results = self.query_metadata(client, query)
          return nil if results.nil?
          return [ results[0][:numRanIns], results[0][:numTriplesWithRan] ]
        end

        def list_of_properties_domains_ranges(client, graph)
          query = <<-SPARQL
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
SELECT ?p ?d ?r
        FROM <#{graph}>
WHERE{
  ?p rdfs:domain ?d.
  ?p rdfs:range ?r.
}
SPARQL
          results = self.query_metadata(client, query)
          return [] if results.nil?
          results.map { |solution| [ solution[:p], solution[:d], solution[:r] ] }
        end

        def list_of_datatypes(uri, logger: nil)
          query = <<-SPARQL
SELECT DISTINCT (datatype(?o) AS ?ldt)
WHERE{
  [] ?p ?o.
  FILTER(isLiteral(?o))
}
SPARQL
          results = Umakadata::SparqlHelper.query(uri, query, logger: logger)
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

      end
    end
  end
end