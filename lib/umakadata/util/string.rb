module StringExt
  def pluralize(count, word)
    "#{count} #{word.pluralize(count)}"
  end
end
