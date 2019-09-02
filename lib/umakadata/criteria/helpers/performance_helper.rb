require 'umakadata/util/string'

module Umakadata
  module Criteria
    module Helpers
      module PerformanceHelper
        include StringExt

        # @return [Umakadata::Activity]
        def base_query
          endpoint
            .sparql
            .ask
            .where(%i[s p o])
            .execute
            .tap(&post_proc_query)
        end

        # @return [Umakadata::Activity]
        def heavy_query(offset = 0)
          endpoint
            .sparql
            .select(:c)
            .distinct
            .where([::RDF::BlankNode.new, ::RDF::RDFV.type, :c])
            .tap { |x| x.graph(:g) if endpoint.graph_keyword_supported? }
            .limit(100)
            .offset(offset)
            .execute
            .tap(&post_proc_query)
        end

        private

        def post_proc_query
          lambda do |activity|
            activity.type = Activity::Type::EXECUTION_TIME
            activity.comment = "#{activity.query} took #{pluralize(activity.elapsed_time.round(3), 'second')}."
          end
        end
      end
    end
  end
end
