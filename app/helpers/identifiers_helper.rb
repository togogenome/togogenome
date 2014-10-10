module IdentifiersHelper
  def hit_count_message(count)
    number_with_delimiter = number_with_delimiter(count)
    mss = (count > 100) ? "Showing 100 of #{number_with_delimiter} results" : "Showing #{number_with_delimiter} results"
    content_tag(:p, mss)
  end
end
