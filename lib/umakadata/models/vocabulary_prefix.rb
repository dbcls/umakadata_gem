require 'fileutils'

module Umakadata
  # A class that represents Vocabulary Prefix
  #
  # @since 1.0.0
  class VocabularyPrefix
    class << self
      CACHE_FILE_NAME = 'vocabulary_prefix.json'.freeze

      EXCLUDE_PATTERNS = [
        /www.openlinksw.com/
      ].freeze

      # Obtain a list of Linked Open Vocabularies
      #
      # @return [Array<String>]
      def all
        @all ||= if File.exist?(cache_path)
                   JSON.parse(File.read(cache_path))
                 else
                   []
                 end
      end

      def exclude_patterns
        EXCLUDE_PATTERNS
      end

      private

      def cache_path
        File.join(Umakadata::Crawler.config.app_home, CACHE_FILE_NAME)
      end
    end
  end
end
