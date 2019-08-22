require 'umakadata/criteria/base'

module Umakadata
  module Criteria
    class Operation < Base
      MEASUREMENT_NAMES = {
        service_description?: 'operation.service_description',
        void?: 'operation.void'
      }.freeze

      # Check whether if the endpoint provides service description
      #
      # @return [Umakadata::Measurement]
      def service_description?
        activity = endpoint.service_description

        Measurement.new do |m|
          m.name = MEASUREMENT_NAMES[__method__]
          m.value = (test = (200..299).include?(activity.response&.status))
          m.comment = if test && activity.result.present?
                        'The endpoint provides Service Description.'
                      else
                        'The endpoint does not provide Service Description.'
                      end
          m.activities << activity
        end
      end

      # Check whether if the endpoint provides VoID
      #
      # @return [Umakadata::Measurement]
      def void?
        activity = endpoint.void

        Measurement.new do |m|
          m.name = MEASUREMENT_NAMES[__method__]
          m.value = (test = (200..299).include?(activity.response&.status))
          m.comment = if test && activity.result.present?
                        'The endpoint provides VoID.'
                      else
                        'The endpoint does not provide VoID.'
                      end
          m.activities << activity
        end
      end
    end
  end
end
