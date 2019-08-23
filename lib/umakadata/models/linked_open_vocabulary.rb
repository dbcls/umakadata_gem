require 'fileutils'

module Umakadata
  # A class that represents data model for Linked Open Vocabularies
  #
  # @see https://lov.linkeddata.es/dataset/lov/
  #
  # @since 1.0.0
  class LinkedOpenVocabulary
    class << self
      LOV_CACHE_FILE_NAME = 'lov.json'.freeze

      # Obtain a list of Linked Open Vocabularies
      #
      # @return [Array<Object>, nil]
      def all
        update
        lov_from_cache.map { |x| x['nsp'] }
      end

      def update(force: false)
        if File.exist?(cache_path)
          return unless force || expired?
        end

        logger.info('Updating cache for Linked Open Vocabularies')

        lov_from_remote do |lov|
          File.open(cache_path, 'w') { |f| f.write JSON.dump(lov) }
          logger.info('Successfully updated cache for Linked Open Vocabularies')
        end
      end

      def expired?
        return unless File.exist?(cache_path)

        Time.now - File::Stat.new(cache_path).mtime > 60 * 60 * 24 # 1 day
      end

      private

      def cache_path
        File.join(Umakadata::Crawler.config.app_home, LOV_CACHE_FILE_NAME)
      end

      def lov_from_cache
        JSON.parse(File.read(cache_path)) if File.exist?(cache_path)
      end

      def lov_from_remote
        url = Umakadata::Crawler.config.lov

        activity = Umakadata::HTTP::Client.new(url).get(url, Accept: 'application/json')

        return unless (200..299).include?(activity.response&.status)

        Array(activity.result).tap do |result|
          yield result if block_given?
        end
      end

      def logger
        @logger ||= ::Logger.new((options = Umakadata::Crawler.config.logger.options).delete(:logdev), options)
      end
    end
  end
end
