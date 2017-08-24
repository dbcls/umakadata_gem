require 'rdf/turtle'
require 'rdf/rdfxml'

module Umakadata
  module DataFormat

    UNKNOWN = 'unknown'
    TURTLE = 'text/turtle'.freeze
    RDFXML = 'application/rdf+xml'.freeze
    HTML   = 'text/html'.freeze

    def xml?(str)
      return !make_reader_for_xml(str).nil?
    end

    def ttl?(str)
      return !make_reader_for_ttl(str).nil?
    end

    def make_reader_for_xml(str)
      begin
        reader = RDF::RDFXML::Reader.new(str, {validate: true})
        return reader
      rescue
        return nil
      end
    end

    def make_reader_for_ttl(str)
      begin
        str = str.gsub(/@prefix\s*:\s*?<#>\s*\.\n/, '')
        str = str.gsub(/<>/, '<http://blank>')
        reader = RDF::Graph.new << RDF::Turtle::Reader.new(str, {validate: true})
        return reader
      rescue
        return nil
      end
    end

    def triples(str, type=nil)
      return nil if str.nil? || str.empty?

      reader = nil
      if type == TURTLE || (type.nil? && ttl?(str))
        reader = make_reader_for_ttl(str)
      elsif type == RDFXML || (type.nil? && xml?(str))
        reader = make_reader_for_xml(str)
        if !reader.nil?
          class <<reader
            def uri(value, append = nil)
              append = RDF::URI(append)
              value = RDF::URI(value)
              value = if append.absolute?
                        value = append
                      elsif append
                        value = value.join(append)
                      else
                        value
                      end
              # comment out since validate? does not consider blank nodes
              # value.validate! if validate?
              value.canonicalize! if canonicalize?
              value = RDF::URI.intern(value) if intern?
              value
            end
          end
        end
      end
      return nil if reader.nil?

      data = []
      begin
        reader.each_triple do |subject, predicate, object|
          data.push [subject, predicate, object]
        end
      rescue
         puts $!
      end
      return data
    end

  end
end
