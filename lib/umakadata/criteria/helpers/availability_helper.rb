require 'umakadata/util/cacheable'

module Umakadata
  module Criteria
    module Helpers
      module AvailabilityHelper
        include Cacheable

        # @param [Hash{Symbol => Object}] options
        # @option options [true, false] :graph
        # @return [Umakadata::Activity]
        def liveness(**options)
          cache(:liveness, options) do
            endpoint
              .sparql
              .construct(%i[s p o])
              .tap { |x| x.graph(:g) if options[:graph] }
              .where(%i[s p o])
              .limit(1)
              .execute
              .tap do |act|
              status = act.response&.status
              reason = act.response&.reason_phrase
              act.type = Activity::Type::ALIVE
              act.comment = if status || reason
                              "The endpoint returns #{status || 'N/A'} #{reason || 'N/A'}."
                            else
                              'Failed to obtain response status.'
                            end
            end
          end
        end
      end
    end
  end
end
