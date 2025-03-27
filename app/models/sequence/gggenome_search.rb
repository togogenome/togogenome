require 'ostruct'

module Sequence

  class GggenomeSearchError < StandardError; end

  module GggenomeSearch
    class << self
      def search(sequence, url = 'https://gggenome.dbcls.jp/togogenome', format = 'json')
        result = Rails.cache.fetch Digest::MD5.hexdigest(sequence), expires_in: 1.day do
          client = HTTPClient.new
          client.get_content("#{url}/#{sequence}.#{format}")
        end

        gggenome = JSON.parse(result, {symbolize_names: true})

        raise GggenomeSearchError, "[GGGenome Error] #{gggenome[:error]}" unless gggenome[:error] == 'none'

        gggenome[:results].map {|r| OpenStruct.new(r) }
      end
    end
  end
end
