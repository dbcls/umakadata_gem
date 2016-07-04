require 'umakadata/retriever'

module Umakadata
  class NotSupportGraphRetriever < Umakadata::Retriever

    include Umakadata::Criteria::NotSupportGraph::ExecutionTime
    def execution_time(logger: nil)
      super(@uri, logger: logger)
    end

    include Umakadata::Criteria::NotSupportGraph::ContentNegotiation
    def check_content_negotiation(content_type, logger: nil)
      super(@uri, content_type, logger: logger)
    end

    include Umakadata::Criteria::NotSupportGraph::LinkedDataRules
    def uri_subject?(logger: nil)
      super(@uri, logger: logger)
    end

    def http_subject?(logger: nil)
      super(@uri, logger: logger)
    end

    def uri_provides_info?(logger: nil)
      super(@uri, logger: logger)
    end

    def contains_links?(logger: nil)
      super(@uri, logger: logger)
    end

  end
end
