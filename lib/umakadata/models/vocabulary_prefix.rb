require 'fileutils'

module Umakadata
  # A class that represents Vocabulary Prefix
  #
  # @since 1.0.0
  class VocabularyPrefix
    class << self
      EXCLUDE_PATTERNS = [
        /www.openlinksw.com/
      ].freeze

      def exclude_patterns
        EXCLUDE_PATTERNS
      end
    end
  end
end
