require 'rdf/turtle'
require 'rdf/rdfxml'
require 'rdf/n3'
require 'rdf/ntriples'
require 'rdf/rdfa'

module Umakadata
  module DataFormat

    UNKNOWN  = 'unknown'
    TURTLE   = 'text/turtle'.freeze
    RDFXML   = 'application/rdf+xml'.freeze
    HTML     = 'text/html'.freeze
    N3       = 'text/n3'.freeze
    NTRIPLES = 'application/n-triples'.freeze
    RDFA     = 'application/xhtml+xml'.freeze
    JSONLD   = 'application/ld+json'.freeze

    def xml?(str)
      return !make_reader_for_xml(str).nil?
    end

    def ttl?(str)
      return !make_reader_for_ttl(str).nil?
    end

    def n3?(str)
      return !make_reader_for_n3(str).nil?
    end

    def ntriples?(str)
      return !make_reader_for_ntriples(str).nil?
    end

    def rdfa?(str)
      return !make_reader_for_rdfa(str).nil?
    end

    def jsonld?(str)
      return !make_reader_for_jsonld(str).nil?
    end

    def make_reader_for_xml(str)
      begin
        return nil unless RDF::RDFXML::Format.detect(str)
        reader = RDF::RDFXML::Reader.new(str, { validate: true })
        return reader
      rescue
        return nil
      end
    end

    def make_reader_for_ttl(str)
      begin
        str = str.gsub(/@prefix\s*:\s*?<#>\s*\.\n/, '')
        str = str.gsub(/<>/, '<http://blank>')
        return nil unless RDF::Turtle::Format.detect(str)
        reader = RDF::Graph.new << RDF::Turtle::Reader.new(str, { validate: true })
        return reader
      rescue
        return nil
      end
    end

    def make_reader_for_n3(str)
      begin
        # TODO return nil if it does not match N3
        reader = RDF::N3::Reader.new(str, { validate: true })
        return reader
      rescue
        return nil
      end
    end

    def make_reader_for_ntriples(str)
      begin
        return nil unless RDF::NTriples::Format.detect(str)
        reader = RDF::NTriples::Reader.new(str, { validate: true })
        return reader
      rescue
        return nil
      end
    end

    def make_reader_for_rdfa(str)
      begin
        return nil unless RDF::RDFa::Format.detect(str)
        reader = RDF::RDFa::Reader.new(str, { validate: true })
        return reader
      rescue
        return nil
      end
    end

    def make_reader_for_jsonld(str)
      begin
        return nil unless JSON::LD::Format.detect(str)
        reader = JSON::LD::Reader.new(str, { validate: true })
        return reader
      rescue
        return nil
      end
    end

    def triples(str, type = nil)
      return nil if str.nil? || str.empty?

      reader = nil
      if type == NTRIPLES || (type.nil? && ntriples?(str))
        reader = make_reader_for_ntriples(str)
      elsif type == TURTLE || (type.nil? && ttl?(str))
        reader = make_reader_for_ttl(str)
      elsif type == RDFXML || (type.nil? && xml?(str))
        reader = make_reader_for_xml(str)
        if !reader.nil?
          class << reader
            def uri(value, append = nil)
              append = RDF::URI(append)
              value  = RDF::URI(value)
              value  = if append.absolute?
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
      elsif type == N3 || (type.nil? && n3?(str))
        reader = make_reader_for_n3(str)
        if !reader.nil?
          class << reader
            def uri(value, append = nil)
              value = RDF::URI(value)
              value = value.join(append) if append
              # comment out since validate? does not consider blank nodes
              # value.validate! if validate? && value.respond_to?(:validate)
              value.canonicalize! if canonicalize?
              value = RDF::URI.intern(value, {}) if intern?

              # Variable substitution for in-scope variables. Variables are in scope if they are defined in anthing other than
              # the current formula
              var   = @variables[value.to_s]
              value = var[:var] if var

              value
            end
          end
        end
      elsif type == RDFA || (type.nil? && rdfa?(str))
        reader = make_reader_for_rdfa(str)
        if !reader.nil?
          class << reader
            def uri(value, append = nil)
              append = RDF::URI(append)
              value  = RDF::URI(value)
              value  = if append.absolute?
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
            rescue ArgumentError => e
              raise RDF::ReaderError, e.message
            end
          end
        end
      elsif type == JSONLD || (type.nil? && jsonld?(str))
        reader = make_reader_for_jsonld(str)
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
      return nil if data.empty?
      return data
    end

  end
end
