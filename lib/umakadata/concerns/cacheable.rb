require 'active_support/concern'

module Umakadata
  module Cacheable
    # @param [Object] namespace
    # @param [Object] key
    # @param [Proc] block
    # @return [Object] cached value
    def cache(namespace = caller[0], key: nil, &block)
      @cache ||= Hash.new { |h, k| h[k] = {} }
      @cache[namespace][key] ||= block.call
    end
  end
end
