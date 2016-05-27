require "umakadata/criteria/liveness"
require "umakadata/criteria/service_description"
require "umakadata/criteria/linked_data_rules"
require "umakadata/criteria/void"
require "umakadata/criteria/execution_time"
require "umakadata/criteria/cool_uri"
require "umakadata/criteria/content_negotiation"
require "umakadata/criteria/metadata"
require "umakadata/criteria/basic_sparql"

module Umakadata
  class Retriever

    include ErrorHelper

    def initialize(uri)
      @uri = URI(uri)
    end

    include Umakadata::Criteria::Liveness
    def alive?(time_out = 30, logger: nil)
      super(@uri, time_out, logger: logger)
    end

    include Umakadata::Criteria::ServiceDescription
    def service_description(time_out = 30, logger: nil)
      super(@uri, time_out, logger: logger)
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

    include Umakadata::Criteria::VoID
    def well_known_uri
      super(@uri)
    end
    def void_on_well_known_uri(time_out = 30, logger: nil)
      super(@uri, time_out, logger: logger)
    end

    include Umakadata::Criteria::ExecutionTime
    def execution_time(logger: nil)
      super(@uri, logger: logger)
    end

    include Umakadata::Criteria::CoolURI
    def cool_uri_rate(logger: nil)
      super(@uri, logger: logger)
    end

    include Umakadata::Criteria::ContentNegotiation
    def check_content_negotiation(content_type, logger: nil)
      super(@uri, content_type, logger: logger)
    end

    include Umakadata::Criteria::Metadata
    def metadata(logger: nil)
      super(@uri, logger: logger)
    end

    def last_updated
      sd   = self.service_description
      return { date: sd.modified, source: 'ServiceDescription' } unless sd.nil? || sd.modified.nil?

      void = self.void_on_well_known_uri
      return { date: void.modified, source: 'VoID' } unless void.nil? || void.modified.nil?

      return nil
    end

    def count_first_last
      sparql = Umakadata::Criteria::BasicSPARQL.new(@uri)
      count = sparql.count_statements

      return { count: nil, first: nil, last: nil } if count.nil?

      first = sparql.nth_statement(0)
      last  = sparql.nth_statement(count - 1)
      return { count: count, first: first, last: last }
    end

    def number_of_statements(logger: nil)
      sparql = Umakadata::Criteria::BasicSPARQL.new(@uri)
      return sparql.count_statements(logger: logger)
    end

  end
end
