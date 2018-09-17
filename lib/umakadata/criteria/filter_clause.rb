require 'active_support'
require 'active_support/core_ext'

module Umakadata
  module Criteria
    module FilterClause
      def filter_clause(allow_prefix, deny_prefix, case_sensitive)
        if allow_prefix.present? && deny_prefix.present?
          if case_sensitive
            "(regex(str(?s), \"^#{allow_prefix}\") AND !regex(str(?s), \"^#{deny_prefix}\"))"
          else
            "(regex(str(?s), \"^#{allow_prefix}\", \"i\") AND !regex(str(?s), \"^#{deny_prefix}\", \"i\"))"
          end
        elsif allow_prefix.present?
          if case_sensitive
            "regex(str(?s), \"^#{allow_prefix}\")"
          else
            "regex(str(?s), \"^#{allow_prefix}\", \"i\")"
          end
        elsif deny_prefix.present?
          if case_sensitive
            "!regex(str(?s), \"^#{deny_prefix}\")"
          else
            "!regex(str(?s), \"^#{deny_prefix}\", \"i\")"
          end
        else
          raise StandardError.new('Neither allow_regex nor deny_regex is specified: one of them must be specified.')
        end
      end
    end
  end
end