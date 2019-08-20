module Umakadata
  class Criteria
    class Availability < Criteria
      MEASUREMENT_NAMES = {
        alive?: 'availability.alive'
      }.freeze

      # Check whether if the endpoint is alive or dead
      #
      # @yield [measurement]
      # @yieldparam [Umakadata::Measurement]
      #
      # @return [true, false] true if the endpoint is alive
      def alive?
        activities = []

        [check_liveness_with_graph, check_liveness_without_graph].each do |query|
          activities << (query.execute.tap do |act|
            act.type = Activity::Type::ALIVE
            status = act.response&.status || 'N/A'
            reason = act.response&.reason_phrase || 'N/A'
            act.comment = "The endpoint returns #{status} #{reason}"
          end)
          break if activities.last&.response&.status == 200
        end

        if block_given?
          measurement = Umakadata::Measurement.new(MEASUREMENT_NAMES[__method__], nil, activities) do |m|
            m.comment = case activities.last&.response&.status
                        when 100..199, 300..499
                          'It is unknown whether the endpoint is alive or dead.'
                        when 200..299
                          'The endpoint is alive.'
                        when 500..599
                          'The endpoint is dead.'
                        else
                          'Errors occurred in checking liveness of the endpoint.'
                        end
          end

          yield measurement
        end

        activities.last&.response&.status == 200 || false
      end

      private

      def check_liveness_with_graph
        check_liveness_without_graph
          .graph(:g)
      end

      def check_liveness_without_graph
        endpoint
          .sparql
          .construct(%i[s p o])
          .where(%i[s p o])
          .limit(1)
      end
    end
  end
end
