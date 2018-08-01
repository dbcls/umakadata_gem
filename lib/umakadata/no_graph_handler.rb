require "umakadata/criteria/sparql_without_graph/content_negotiation"
require "umakadata/criteria/sparql_without_graph/linked_data_rules"
require "umakadata/criteria/sparql_without_graph/metadata"

module Umakadata
  class NoGraphHandler

    def initialize(uri)
      @uri = URI(uri)
    end

    include Umakadata::Criteria::SPARQLWithoutGraph::ContentNegotiation
    def check_content_negotiation(allowed_prefix, denied_prefix, case_sensitive, content_type, logger: nil)
      super(@uri, allowed_prefix, denied_prefix, case_sensitive, content_type, logger: logger)
    end

    def check_endpoint(content_type, logger: nil)
      super(@uri, content_type, logger: logger)
    end

    include Umakadata::Criteria::SPARQLWithoutGraph::LinkedDataRules
    def http_subject?(number_of_statements, logger: nil)
      super(@uri, number_of_statements, logger: logger)
    end

    def uri_provides_info?(prefixes, logger: nil)
      super(@uri, prefixes, logger: logger)
    end

    def contains_links?(prefixes, logger: nil)
      super(@uri, prefixes, logger: logger)
    end

    include Umakadata::Criteria::SPARQLWithoutGraph::Metadata
    def metadata(logger: nil)
      super(@uri, logger: logger)
    end
    def score_metadata(metadata, logger: nil)
      super(metadata, logger: logger)
    end
    def list_ontologies(metadata, logger: nil)
      super(metadata, logger: logger)
    end
    def list_ontologies_in_LOV(metadata, logger: nil)
      super(metadata, logger: logger)
    end
    def score_ontologies_for_endpoints(metadata, rdf_prefixes, logger: nil)
      super(metadata, rdf_prefixes, logger: logger)
    end
    def score_ontologies_for_LOV(metadata, lov, logger: nil)
      super(metadata, lov, logger: logger)
    end
  end
end
