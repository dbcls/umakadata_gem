require 'umakadata/criteria/base'
require 'umakadata/criteria/helpers/availability_helper'

module Umakadata
  module Criteria
    class Availability < Base
      include Helpers::AvailabilityHelper

      MEASUREMENT_NAMES = {
        alive: 'availability.alive'
      }.freeze

      # Check whether if the endpoint is alive or dead
      #
      # @return [Umakadata::Measurement]
      def alive
        activities = []
        status = nil

        [true, false].each do |bool|
          activities << __send__(:check_alive, graph: bool)
          break if (status = activities.last&.response&.status) == 200
        end

        Umakadata::Measurement.new do |m|
          m.name = MEASUREMENT_NAMES[__method__]
          m.value = status == 200
          m.comment = case status
                      when 100..199, 300..499
                        'It is unknown whether the endpoint is alive or dead.'
                      when 200..299
                        'The endpoint is alive.'
                      when 500..599
                        'The endpoint is dead.'
                      else
                        "Errors occurred in checking liveness of the endpoint. (status = #{status})"
                      end
          m.activities = activities
        end
      end
    end
  end
end
