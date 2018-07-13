require 'sparql/client'
require 'umakadata/http_header'
require 'umakadata/data_format'

module Umakadata
  class SparqlClient < SPARQL::Client

    include Umakadata::DataFormat

    RESULTS = [RESULT_JSON, RESULT_XML, RESULT_BOOL, RESULT_TSV, RESULT_CSV].freeze

    attr_reader :http_request
    attr_reader :http_response

    def pre_http_hook(request)
      request['User-Agent'] = Umakadata::HTTPHeader::USER_AGENT
      @http_request         = request
    end

    def post_http_hook(response)
      @http_response = response
    end

    def parse_rdf_serialization(response, options = {})
      RESULTS.each do |result|
        begin
          solutions = parse_response(response, { :content_type => result })
          return solutions
        rescue
        end
      end
      raise RDF::ReaderError, "no suitable rdf reader was found."
    end

    def parse_response(response, options = {})
      case options[:content_type] || response.content_type
      when NilClass
        response.body
      when RESULT_BOOL
        response.body == 'true'
      when RESULT_JSON
        self.class.parse_json_bindings(response.body, nodes)
      when RESULT_XML
        self.class.parse_xml_bindings(response.body, nodes)
      when RESULT_CSV
        self.class.parse_csv_bindings(response.body, nodes)
      when RESULT_TSV
        self.class.parse_tsv_bindings(response.body, nodes)
      when TURTLE, RDFXML
        options = { :content_type => response.content_type } unless options[:content_type]
        if reader = RDF::Reader.for(options)
          reader.new(response.body)
        else
          raise RDF::ReaderError, "no suitable rdf reader was found."
        end
      when HTML
        response
      else
        parse_rdf_serialization(response, options)
      end
    end

  end
end
