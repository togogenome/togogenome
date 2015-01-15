module SequenceHelper
  # スニペット中のマッチした塩基配列を強調表示して返す。
  # ==== Parameters
  # * snippet - スニペット
  # * snippet_pos_beg - スニペットの開始位置
  # * match_pos_beg - マッチ開始位置
  # * match_pos_end - マッチ終了位置
  # * unmatch_region - マッチした箇所の前後に表示するスニペット数
  # ==== Returns
  # * マッチした塩基配列が強調表示されたスニペット
  # ==== Examples
  #   match_snippet('abcdefghijklmnopqrstuvwxyz', 100, 111, 114, 10)
  #   #=> "bcdefghijk<strong>lmno</strong>pqrstuvwxy"
  def match_snippet(snippet, snippet_pos_beg, match_pos_beg, match_pos_end, unmatch_region = 10)
    match_relative_pos_beg = match_pos_beg.to_i - snippet_pos_beg.to_i
    match_relative_pos_end = match_pos_end.to_i - snippet_pos_beg.to_i

    pre_match  = snippet[(match_relative_pos_beg - unmatch_region), unmatch_region].to_s
    match      = content_tag(:strong, snippet[(match_relative_pos_beg)..match_relative_pos_end] )
    post_match = snippet[(match_relative_pos_end + 1), unmatch_region].to_s

    (pre_match + match + post_match).html_safe
  end
end
