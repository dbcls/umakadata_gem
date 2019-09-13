module Umakadata
  # A class that represents a measurement of an Umakadata evaluation
  #
  # @attr [String] name
  # @attr [Object] value
  # @attr [String] comment
  # @attr [Array<Umakadata::Activity>] activities
  # @attr [Array<Exception>] exceptions
  #
  # @since 1.0.0
  class Measurement
    attr_accessor :name
    attr_accessor :value
    attr_accessor :comment
    attr_accessor :activities
    attr_accessor :exceptions

    def initialize(**attr)
      @name = attr.fetch(:name, nil)
      @value = attr.fetch(:value, nil)
      @comment = attr.fetch(:comment, nil)
      @activities = attr.fetch(:activities, [])
      @exceptions = []

      yield self if block_given?
    end

    def safe
      begin
        yield self
      rescue StandardError => e
        @comment = e.message
        @exceptions << e
      end

      self
    end

    def to_h
      {
        name: @name,
        value: @value,
        comment: @comment,
        activities: @activities.map(&:to_h),
        exceptions: if Crawler.config.backtrace
                      @exceptions.map.with_index(1) { |e, i| [i, e.backtrace.unshift(e.message)] }.to_h
                    else
                      @exceptions.map.with_index(1) { |e, i| [i, e.message] }.to_h
                    end
      }
    end
  end
end
