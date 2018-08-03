require 'singleton'
require 'umakadata/http_helper'

module Umakadata
  class LinkedOpenVocabularies
    include Singleton
    include Umakadata::HTTPHelper

    LOV = 'https://lov.linkeddata.es/dataset/lov/api/v2/vocabulary/list'.freeze

    def initialize
      @list_ontologies = Array.new
    end

    def get(logger: nil)
      unless @list_ontologies.empty?
        logger.result = "#{@list_ontologies.count} vocabularies in LOV were cached" unless logger.nil?
        return @list_ontologies
      end

      log = Umakadata::Logging::Log.new
      logger.push log unless logger.nil?
      args = {:logger => log}

      response = http_get(LOV, args)

      if !response.is_a?(Net::HTTPSuccess)
        log.result = "HTTP response is not 2xx Success"
        logger.result = "Vocabulary list in LOV is not fetchable" unless logger.nil?
        return Array.new
      end

      if response.body.empty?
        log.result = "LOV API does not return any data"
        logger.result = "Vocabulary list in LOV is not fetchable" unless logger.nil?
        return Array.new
      end

      log.result = 'LOV returns 200 HTTP response'

      json = JSON.parse(response.body)
      @list_ontologies = json.map do |elm|
        uri = elm['uri']
        uri.include?('#') ? uri.split('#')[0] : uri
      end
      @list_ontologies.uniq!
      logger.result = "#{@list_ontologies.count} vocabularies in LOV are found" unless logger.nil?
      @list_ontologies
    end
  end
end
