require 'active_support'
require 'active_support/core_ext/numeric/conversions'

module StringExt
  def pluralize(count, word)
    "#{Integer(count).to_s(:delimited)} #{word.pluralize(count)}"
  end
end
