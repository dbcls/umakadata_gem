module Umakadata
  class Endpoint
    module CacheHelper
      # @param [Object] namespace
      # @param [Object] key
      # @param [Proc] block
      # @return [Object] cached value
      def cache(namespace, key = nil, &block)
        @cache ||= Hash.new { |h, k| h[k] = {} }
        @cache[namespace][key] ||= block.call
      end
    end
  end
end
