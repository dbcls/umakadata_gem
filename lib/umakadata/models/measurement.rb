module Umakadata
  # A class that represents a measurement of an Umakadata evaluation
  #
  # @attr [String] name
  # @attr [Object] value
  # @attr [String] comment
  # @attr [Array<Umakadata::Activity>] activities
  #
  # @since 1.0.0
  class Measurement
    attr_accessor :name
    attr_accessor :value
    attr_accessor :comment
    attr_accessor :activities

    def initialize(**attr)
      @name = attr.fetch(:name, nil)
      @value = attr.fetch(:value, nil)
      @comment = attr.fetch(:comment, nil)
      @activities = attr.fetch(:activities, [])

      yield self if block_given?
    end

    def to_h
      {
        name: @name,
        value: @value,
        comment: @comment,
        activities: @activities.map(&:to_h)
      }
    end
  end
end
