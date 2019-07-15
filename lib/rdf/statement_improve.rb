require 'rdf'

module RDF
  class Statement
    alias match? ===
  end
end
