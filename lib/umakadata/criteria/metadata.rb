require 'umakadata/error_helper'
require 'umakadata/logging/log'


module Umakadata
  module Criteria
    module Metadata

      REGEXP = /<title>(.*)<\/title>/

      include Umakadata::ErrorHelper

      SKIP_GRAPH_LIST = [
        'http://www.openlinksw.com/schemas/virtrdf#'
      ]

      def metadata(uri, logger: nil)
        graphs_log = Umakadata::Logging::Log.new
        logger.push graphs_log unless logger.nil?
        graphs = self.list_of_graph_uris(uri, logger: graphs_log)
        metadata = {}
        if graphs.empty?
          graphs_log.result = 'No graphs are found in the endpoint'
          return metadata
        end
        graphs_log.result = "#{graphs.size} graphs are found in the endpoint"

        graphs.each do |graph|
          classes_log = Umakadata::Logging::Log.new
          classes = self.classes_on_graph(uri, graph, logger: classes_log)

          labels_log = Umakadata::Logging::Log.new
          labels_search_log = Umakadata::Logging::Log.new
          labels_log.push labels_search_log
          labels = list_of_labels_of_classes(uri, graph, classes, logger: labels_search_log)
          labels_search_log.result = "#{labels.size} lables are found"

          datatypes_log = Umakadata::Logging::Log.new
          datatypes_search_log = Umakadata::Logging::Log.new
          datatypes_log.push datatypes_search_log
          if IGNORE_ENDPOINTS.has_key?(uri.to_s) and IGNORE_ENDPOINTS[uri.to_s].include?('datatypes')
            datatypes = []
            datatypes_search_log.result = 'skip to count datatypes according to the configurations'
          else
            datatypes = self.list_of_datatypes(uri, graph, logger: datatypes_search_log)
            datatypes_search_log.result = "#{datatypes.size} datatypes are found"
          end

          properties_log = Umakadata::Logging::Log.new
          properties_search_log = Umakadata::Logging::Log.new
          properties_log.push properties_search_log
          properties = self.list_of_properties_on_graph(uri, graph, logger: properties_search_log)
          properties_search_log.result = "#{properties.size} properties are found"

          metadata[graph] = {
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

        return metadata
      end

      def score_metadata(metadata, logger: nil)
        score_proc = lambda do |graph, data|
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

          graph_log.result = "Score for #{graph} is #{total_score}"
          total_score
        end
        metadata_score = self.score_each_graph(metadata, score_proc)
        logger.result = "Metadata score is #{metadata_score}" unless logger.nil?
        metadata_score
      end

      def score_ontologies_for_endpoints(ontologies, rdf_prefixes, logger: nil)
        log = Umakadata::Logging::Log.new
        logger.push log unless logger.nil?
        used_ontologies = 0
        ontologies.each do |ontology|
          includes_ontology_log = Umakadata::Logging::Log.new
          log.push includes_ontology_log
          if rdf_prefixes.include?(ontology)
            used_ontologies += 1
            includes_ontology_log.result = "#{ontology} is used in other endpoints"
          else
            includes_ontology_log.result = "#{ontology} is not used in other endpoints"
          end
        end
        score = ((used_ontologies.to_f / ontologies.count.to_f) * 100) / 2
        log.result = "#{used_ontologies} ontologies are used in other endpoints"
        logger.result = "Ontology score (among other endpoints) is #{score}" unless logger.nil?
        score < 0 ? 0 : score
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
        log.result = "#{used_ontologies} / #{ontologies.count} ontologies match vocabularies in LOV"
        logger.result = "Ontology score (Linked Open Vocabularies) is #{score}" unless logger.nil?
        score < 0 ? 0 : score
      end

      def list_ontologies(metadata, logger: nil)
        list = Array.new
        metadata.each do |graph, data|
          next if SKIP_GRAPH_LIST.include?(graph.to_s)
          properties_log = data[:properties_log]
          logger.push properties_log unless logger.nil?
          properties = data[:properties]
          if properties.empty?
            properties_log.result = "0 ontologies are found in #{graph}"
            next
          end

          ontologies = self.ontologies(properties)
          properties_log.result = "#{ontologies.count} ontologies are found in #{graph}"
          list.push ontologies
        end
        list_ontologies = list.flatten.uniq
        logger.result = "#{list_ontologies.count} ontologies are found in graphs" unless logger.nil?
        list_ontologies
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

      def score_each_graph(metadata, score_proc)
        return 0 if metadata.nil? || metadata.empty?

        score_list = []
        metadata.each do |graph, data|
          next if SKIP_GRAPH_LIST.include?(graph.to_s)
          score_list.push(score_proc.call(graph, data))
        end

        return 0 if score_list.empty?
        return score_list.inject(0.0) { |r, i| r += i } / score_list.size
      end

      def list_of_graph_uris(uri, logger: nil)
        query = <<-SPARQL
SELECT DISTINCT ?g
WHERE {
  GRAPH ?g
  { ?s ?p ?o. }
}
SPARQL
        message = "An error occurred in retrieving graph URIs"
        results = metadata_query(uri, query, message, logger: logger)

        return [] if results.nil?
        results.map { |solution| solution[:g] }
      end

      def classes_on_graph(uri, graph, logger: nil)
        classes = []

        classes_on_graph_log = Umakadata::Logging::Log.new
        logger.push classes_on_graph_log unless logger.nil?
        classes_on_graph = self.list_of_classes_on_graph(uri, graph, logger: classes_on_graph_log)
        classes_on_graph_log.result = "#{classes_on_graph.size} lists of classes on graph are found"

        classes_having_instances_log = Umakadata::Logging::Log.new
        logger.push classes_having_instances_log unless logger.nil?
        classes_having_instances = self.list_of_classes_having_instances(uri, graph, logger: classes_having_instances_log)
        classes_having_instances_log.result = "#{classes_having_instances.size} lists of classes having instances are found"

        classes += classes_on_graph += classes_having_instances
        classes.uniq!
        return classes
      end

      def list_of_classes_on_graph(uri, graph, logger: nil)
        query = <<-SPARQL
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
SELECT DISTINCT ?c
FROM <#{graph}>
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

      def list_of_classes_having_instances(uri, graph, logger: nil)
        query = <<-SPARQL
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
SELECT DISTINCT ?c
FROM <#{graph}>
WHERE { [] rdf:type ?c. }
SPARQL
        message = "An error occurred in retrieving the classes having instances"
        results = metadata_query(uri, query, message, logger: logger)

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

      def list_of_labels_of_classes(uri, graph, classes, logger: nil)
        query = <<-SPARQL
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
SELECT DISTINCT ?c ?label
WHERE {
    graph <#{graph}> {
      ?c rdfs:label ?label.
      filter (
        ?c IN (<#{classes.join('>,<')}>)
      )
    }
}
SPARQL
        message = "An error occurred in retrieving a list of labels"
        results = metadata_query(uri, query, message, logger: logger)

        return [] unless results.is_a?(RDF::Query::Solutions)
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

      def list_of_properties_on_graph(uri, graph, logger: nil)
        query = <<-SPARQL
SELECT DISTINCT ?p
        FROM <#{graph}>
WHERE{
        ?s ?p ?o.
}
SPARQL
        message = "An error occurred in retrieving a list of properties"
        results = metadata_query(uri, query, message, logger: logger)

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

      def list_of_datatypes(uri, graph, logger: nil)
        query = <<-SPARQL
SELECT DISTINCT (datatype(?o) AS ?ldt)
FROM <#{graph}>
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
