require 'umakadata/criteria/base'
require 'umakadata/criteria/helpers/availability_helper'

module Umakadata
  module Criteria
    class Availability < Base
      include Helpers::AvailabilityHelper

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
        status = nil

        [true, false].each do |bool|
          activities << __send__(:liveness, graph: bool)
          break if (status = activities.last&.response&.status) == 200
        end

        test = status == 200 || false

        measurement = Umakadata::Measurement.new(MEASUREMENT_NAMES[__method__], nil, activities) do |m|
          m.comment = case status
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

        yield measurement if block_given?

        inject_measurement(test, measurement)
      end
    end
  end
end
