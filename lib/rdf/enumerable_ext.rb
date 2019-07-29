require 'rdf'

module RDF
  module Enumerable
    # @param [RDF::URI] property
    # @return [Array<RDF::Statement>]
    def filter_by_property(property)
      select { |x| x.match? [nil, property, nil] }
    end
  end
end
