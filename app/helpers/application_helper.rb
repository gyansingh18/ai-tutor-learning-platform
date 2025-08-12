module ApplicationHelper
  def calculate_percentage(value, total)
    return 0 if value.nil? || total.nil? || total == 0
    ((value.to_f / total.to_f) * 100).round
  end

  def highlight(text, search_term)
    return text if search_term.blank? || text.blank?

    highlighted = text.gsub(/(#{Regexp.escape(search_term)})/i, '<mark>\1</mark>')
    highlighted.html_safe
  end
end
