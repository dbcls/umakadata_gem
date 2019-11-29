require 'umakadata/concerns/cacheable'

module Umakadata
  module Criteria
    module Helpers
      module AvailabilityHelper
        include Cacheable

        CHECK_ALIVE_POST_PROC = lambda do |activity|
          status = activity.response&.status
          reason = activity.response&.reason_phrase
          activity.type = Activity::Type::ALIVE
          activity.comment = if status || reason
                               "The endpoint returns #{status || 'N/A'} #{reason || 'N/A'}."
                             else
                               'Failed to obtain response status.'
                             end
        end

        # @param [Hash{Symbol => Object}] options
        # @option options [true, false] :graph
        # @return [Umakadata::Activity]
        def check_alive(**options)
          cache(key: options) do
            endpoint
              .sparql
              .construct(%i[s p o])
              .where(%i[s p o])
              .tap { |x| x.graph(:g) if options[:graph] }
              .limit(1)
              .execute
              .tap(&CHECK_ALIVE_POST_PROC)
          end
        end
      end
    end
  end
end
