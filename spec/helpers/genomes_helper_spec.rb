# coding: utf-8

require 'spec_helper'

describe GenomesHelper do
  pending "add some examples to (or delete) #{__FILE__}"
  describe "match_snippet" do
    it '11番目から16番目(要素が0開始として、10から15)の値がタグに囲まれ、その前後5つが出力される' do
      helper.match_snippet('abcdefghijklmnopqrstuvwxyz', 0, 10, 15, 5).should == 'fghij<strong>klmnop</strong>qrstu'
    end

    it '12番目から15番目(要素が100開始として、111から114)の値が強調され、その前後10つが出力される' do
      helper.match_snippet('abcdefghijklmnopqrstuvwxyz', 100, 111, 114).should == 'bcdefghijk<strong>lmno</strong>pqrstuvwxy'
    end
  end
end
