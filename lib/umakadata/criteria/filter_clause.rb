require 'active_support'
require 'active_support/core_ext'

module Umakadata
  module Criteria
    module FilterClause
      def filter_clause(allow, deny, as_regex, case_insensitive)
        as_regex ? regex(allow, deny, case_insensitive) : str_starts(allow, deny)
      end

      def regex(allow, deny, case_insensitive)
        conditions = []
        conditions << %[regex(str(?s), "^#{allow}"#{case_insensitive ? ', "i"' : ''})] if allow && !allow.empty?
        conditions << %[regex(str(?s), "^#{deny}"#{case_insensitive ? ', "i"' : ''})] if deny && !deny.empty?
        conditions.length > 1 ? "(#{conditions.join('&&')})" : conditions.first
      end

      def str_starts(allow, deny)
        conditions = []
        conditions << %[STRSTARTS(STR(?s), "#{allow}")] if allow && !allow.empty?
        conditions << %[!STRSTARTS(STR(?s), "#{deny}")] if deny && !deny.empty?
        conditions.length > 1 ? "(#{conditions.join('&&')})" : conditions.first
      end
    end
  end
end
