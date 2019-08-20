require 'date'

module Umakadata
  class Criteria
    class Operation < Criteria
      MEASUREMENT_NAMES = {
        service_description?: 'operation.service_description',
        void?: 'operation.void'
      }.freeze

      # Check whether if the endpoint provides service description
      #
      # @yield [measurement]
      # @yieldparam [Umakadata::Measurement]
      #
      # @return [true, false] true if the endpoint provides service description
      def service_description?
        activity = endpoint.service_description

        comment = if (test = (200..299).include?(activity.response&.status) && activity.result.present?)
                    'The endpoint provides Service Description.'
                  else
                    'The endpoint does not provide Service Description.'
                  end

        measurement = Measurement.new(MEASUREMENT_NAMES[__method__], comment, [activity])

        yield measurement if block_given?

        inject_measurement(test, measurement)
      end

      # Check whether if the endpoint provides VoID
      #
      # @yield [measurement]
      # @yieldparam [Umakadata::Measurement]
      #
      # @return [true, false] true if the endpoint provides VoID
      def void?
        activity = endpoint.void

        comment = if (test = (200..299).include?(activity.response&.status) && activity.result.present?)
                    'The endpoint provides VoID.'
                  else
                    'The endpoint does not provide VoID.'
                  end

        measurement = Measurement.new(MEASUREMENT_NAMES[__method__], comment, [activity])

        yield measurement if block_given?

        inject_measurement(test, measurement)

      end
    end
  end
end
