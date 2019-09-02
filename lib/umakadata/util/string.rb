require 'active_support'
require 'active_support/core_ext/numeric/conversions'

module StringExt
  def pluralize(count, word)
    if count.is_a?(Float)
      "#{count} #{word.pluralize(count)}"
    else
      "#{Integer(count).to_s(:delimited)} #{word.pluralize(count)}"
    end
  end
end
