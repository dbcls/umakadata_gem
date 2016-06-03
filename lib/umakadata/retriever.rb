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

    def last_updated(logger: nil)
      log = Umakadata::Logging::Log.new
      logger.push log unless logger.nil?

      sd_log = Umakadata::Logging::Log.new
      log.push sd_log
      sd   = self.service_description(logger: sd_log)
      unless sd.nil? || sd.modified.nil?
        log.result = 'The literal of dcterms:modified is found in Service Description'
        sd_log.result = "dcterms:modified is #{sd.modified}"
        return { date: sd.modified, source: 'ServiceDescription' }
      end
      sd_log.result = 'The literal of dcterms:modified is not found in Service Description'

      void_log = Umakadata::Logging::Log.new
      log.push void_log
      void = self.void_on_well_known_uri(logger: void_log)
      unless void.nil? || void.modified.nil?
        log.result = 'The literal of dcterms:modified is found in VoID'
        void_log.result = "dcterms:modified is #{void.modified}"
        return { date: void.modified, source: 'VoID' }
      end
      void_log.result = 'The literal of dcterms:modified is not found in VoID'
      log.result = 'The literal of dcterms:modified is not found in either Service Description or VoID'
      nil
    end

    def count_first_last(logger: nil)
      count_log = Umakadata::Logging::Log.new
      logger.push count_log unless logger.nil?

      sparql = Umakadata::Criteria::BasicSPARQL.new(@uri)
      count = sparql.count_statements(logger: count_log)
      if count.nil?
        count_log.result = 'The latest Statements are not found'
        return { count: nil, first: nil, last: nil }
      end
      count_log.result = "#{count} statements are found"

      first_log = Umakadata::Logging::Log.new
      logger.push first_log unless logger.nil?
      first = sparql.nth_statement(0, logger: first_log)
      if first.nil?
        first_log.result = 'The first statements are not found'
      else
        first_log.result = 'The first statements are found'
      end

      last_log = Umakadata::Logging::Log.new
      logger.push last_log unless logger.nil?
      last  = sparql.nth_statement(count - 1, logger: last_log)
      if last.nil?
        last_log.result = 'The last statements are not found'
      else
        last_log.result = 'The last statements are found'
      end

      return { count: count, first: first, last: last }
    end

    def number_of_statements(logger: nil)
      sparql = Umakadata::Criteria::BasicSPARQL.new(@uri)
      return sparql.count_statements(logger: logger)
    end

  end
end
