require 'fileutils'

module Umakadata
  # Helper methods to obtain Linked Open Vocabularies
  #
  # @see https://lov.linkeddata.es/dataset/lov/
  #
  # @since 1.0.0
  module HTTP
    module LOVHelper
      LOV_CACHE_FILE_NAME = 'lov.json'.freeze

      # Obtain a list of Linked Open Vocabularies
      #
      # @return [Array<Object>, nil]
      def linked_open_vocabulary
        path = File.join(Umakadata::Crawler.config.app_home, LOV_CACHE_FILE_NAME)

        lov_from_cache(path) || lov_from_remote do |lov|
          File.open(path, 'w') { |f| f.write JSON.dump(lov) }
        end
      end

      private

      def lov_from_cache(path)
        return unless File.exist?(path)
        return unless ((Time.now - File::Stat.new(path).mtime) / (60 * 60 * 24)).positive?

        JSON.parse(File.read(path))
      end

      def lov_from_remote
        url = Umakadata::Crawler.config.lov

        activity = Umakadata::HTTP::Client.new(url).get(url, Accept: 'application/json')

        return unless activity.response.status == 200

        Array(activity.result).tap do |result|
          yield result if block_given?
        end
      end
    end
  end
end
