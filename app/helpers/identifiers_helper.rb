module IdentifiersHelper
  def hit_count_message(display_count, hits_count)
    mss = "Showing #{number_with_delimiter(display_count)} of #{number_with_delimiter(hits_count)} results"
    content_tag(:p, mss)
  end
end
