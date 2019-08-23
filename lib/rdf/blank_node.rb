require 'rdf'

module RDF
  class BlankNode < Node
    def initialize
      super('bn')
    end

    def to_s
      '[]'
    end
  end
end
