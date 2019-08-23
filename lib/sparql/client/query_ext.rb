require 'sparql/client'

class SPARQL::Client
  class Query
    class Bind < SPARQL::Client::QueryElement
      def initialize(*args)
        super
      end

      def to_s
        "BIND(#{elements.join(' ')})"
      end
    end
  end
end
