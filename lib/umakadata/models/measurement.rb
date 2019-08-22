module Umakadata
  # A class that represents a measurement of an Umakadata evaluation
  #
  # @attr [String] name
  # @attr [String] comment
  # @attr [Array<Umakadata::Activity>] activities
  #
  # @since 1.0.0
  class Measurement
    attr_accessor :name
    attr_accessor :comment
    attr_accessor :activities

    def initialize(name = nil, comment = nil, activities = [])
      @name = name
      @comment = comment
      @activities = activities

      yield self if block_given?
    end
  end
end
