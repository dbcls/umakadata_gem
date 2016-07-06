require "umakadata/criteria/execution_time"
require "umakadata/criteria/content_negotiation"
require "umakadata/criteria/linked_data_rules"

module Umakadata
  class GraphHandler

    def initialize(uri)
      @uri = URI(uri)
    end

    include Umakadata::Criteria::ExecutionTime
    def execution_time(logger: nil)
      super(@uri, logger: logger)
    end

    include Umakadata::Criteria::ContentNegotiation
    def check_content_negotiation(content_type, logger: nil)
      super(@uri, content_type, logger: logger)
    end

    include Umakadata::Criteria::LinkedDataRules
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
