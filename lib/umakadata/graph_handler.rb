require "umakadata/criteria/execution_time"
require "umakadata/criteria/content_negotiation"
require "umakadata/criteria/linked_data_rules"

module Umakadata
  class GraphHandler

    def initialize(uri)
      @uri = URI(uri)
    end

    include Umakadata::Criteria::ContentNegotiation
    def check_content_negotiation(prefix, content_type, logger: nil)
      super(@uri, prefix, content_type, logger: logger)
    end

    include Umakadata::Criteria::LinkedDataRules
    def http_subject?(logger: nil)
      super(@uri, logger: logger)
    end

    def uri_provides_info?(prefixes, logger: nil)
      super(@uri, prefixes, logger: logger)
    end

    def contains_links?(prefixes, logger: nil)
      super(@uri, prefixes, logger: logger)
    end

    include Umakadata::Criteria::Metadata
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
