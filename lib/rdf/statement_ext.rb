require 'rdf'

module RDF
  class Statement
    alias equal? ===

    # @param [RDF::Statement, Array] pattern
    # @return [true, false]
    def match?(pattern)
      case pattern
      when ::RDF::Statement
        pattern.equal? self
      when Array
        ::RDF::Statement(*pattern).equal? self
      else
        false
      end
    end
  end
end
