require 'umakadata/criteria/base'

module Umakadata
  module Criteria
    class Operation < Base
      MEASUREMENT_NAMES = {
        service_description: 'operation.service_description',
        void: 'operation.void'
      }.freeze

      def measurements
        MEASUREMENT_NAMES.keys.map { |x| method(x) }
      end

      # Check whether if the endpoint provides service description
      #
      # @return [Umakadata::Measurement]
      def service_description
        Umakadata::Measurement.new(name: MEASUREMENT_NAMES[__method__]).safe do |m|
          activity = endpoint.service_description

          m.value = activity.result.is_a?(::RDF::Enumerable) ? activity.response.body : nil
          m.comment = if (200..299).include?(activity.response&.status) && m.value.present?
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
      def void
        Umakadata::Measurement.new(name: MEASUREMENT_NAMES[__method__]).safe do |m|
          activity = endpoint.void

          via_http = (200..299).include?(activity.response&.status) && activity.result.present?
          in_sd = (sd = endpoint.service_description).respond_to?(:void_descriptions) && sd.void_descriptions.present?

          m.value = (r = activity.result).is_a?(::RDF::Enumerable) ? r.to_ttl : nil
          m.comment = if via_http
                        'The endpoint provides VoID.'
                      elsif in_sd
                        'The endpoint provides VoID via Service Description.'
                      else
                        'The endpoint does not provide VoID.'
                      end
          m.activities << activity
        end
      end
    end
  end
end
