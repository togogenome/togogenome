require 'open-uri'

class StanzaSearch
  PAGINATE = {per_page: 10}

  class << self
    def search(q)
      return nil unless q

      # XXX nanostanza は検索してない
      Stanza.ids.map {|id|
        search_by_stanza_id(q, id)
      }.group_by {|e|
        e[:report_type]
      }
    end

    def search_by_stanza_id(q, stanza_id)
      stanza_url = "#{Stanza.providers.togostanza.url}/#{stanza_id}"
      url = "#{stanza_url}/text_search?q=#{URI.encode_www_form_component(q)}"

      stanza_data = Stanza.all.find {|s| s['id'] == stanza_id }

      JSON.parse(get_with_cache(url)).merge(
        {
          stanza_id:    stanza_id,
          stanza_name:  stanza_data['name'],
          report_type:  stanza_data['report_type'],
          stanza_url:   stanza_url
        }
      ).with_indifferent_access
    end

    def searchable?(stanza_id)
      # 検索可能なスタンザか否かを返す。
      # プロバイダーに所属する各スタンザが、テキスト検索に対応しているか否かを取得する仕組みが無いため
      # ハードコードしている
      %w(organism_names organism_phenotype).include?(stanza_id)
    end

    private

    def get_with_cache(url)
      # 「件数取得」と「検索結果取得」で2回同じ検索が行われるのでキャッシュしておく
      Rails.cache.fetch Digest::MD5.hexdigest(url), expires_in: 1.day, compress: true do
        open(url).read
      end
    end
  end
end
