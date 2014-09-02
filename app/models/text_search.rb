require 'open-uri'

class TextSearch
  class << self
    def search(q)
      # XXX nanostanza は検索してない
      Stanza.ids.map {|id|
        search_stanza(id, q)
      }.reject {|e|
        e[:enabled] == false
      }
    end

    def search_stanza(stanza_id, q)
      stanza_url = "#{Stanza.providers.togostanza.url}/#{stanza_id}"
      url = "#{stanza_url}/text_search?q=#{q}"

      res = JSON.parse(get_with_cache(url))
      entry_ids = res['urls'].map {|url| Rack::Utils.parse_query(URI(url).query) }

      Stanza.all.find {|s| s['id'] == stanza_id }.merge(
        {
          url:       stanza_url,
          enabled:   res['enabled'],
          count:     res['count'],
          entry_ids: entry_ids
        }
      ).with_indifferent_access
    end

    private

    def get_with_cache(url)
      # 「件数取得」と「検索結果取得」で2回同じ検索が行われるのでキャッシュしておく
      Rails.cache.fetch Digest::MD5.hexdigest(url), expires_in: 1.day do
        open(url).read
      end
    end
  end
end
