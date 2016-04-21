module Umakadata
  module Linkset

    def linksets(triples)
      linksets = []

      return linksets if triples.nil?

      current = nil
      triples.each do | subject, predicate, object |
        predicate_is_type = predicate == RDF::URI('http://www.w3.org/1999/02/22-rdf-syntax-ns#type')
        object_is_linkset = object == RDF::URI('http://rdfs.org/ns/void#Linkset')
        next if current.nil? && (!predicate_is_type || !object_is_linkset)

        if !current.nil?
          if current != subject
            current = nil
            next
          end
          linksets.push object if predicate == RDF::URI('http://rdfs.org/ns/void#target')
          next
        else
          current = subject if predicate_is_type && object_is_linkset
          next
        end
      end
      return linksets
    end

  end
end
