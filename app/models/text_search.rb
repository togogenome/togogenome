require 'open-uri'

class TextSearch
  class << self
    def search(q)
      # XXX nanostanza は検索してない
      stanza_endpoint = Stanza.providers.togostanza
      stanza_root = stanza_endpoint.url
      name_and_urls = get_stanzas(stanza_endpoint).map {|stanza|
        {name: stanza['name'], url: "#{stanza_root}/#{stanza['id']}"}
      }
      name_and_urls.map {|e|
        search_stanza(e[:name], e[:url], q)
      }.reject {|e|
        e[:enabled] == false
      }
    end

    def search_stanza(stanza_name, stanza_url, q)
      url = "#{stanza_url}/text_search?q=#{q}"
      res = JSON.parse(get_with_cache(url)).with_indifferent_access
      {
        name: stanza_name,
        stanza_url: stanza_url,
        enabled: res[:enabled],
        count: res[:count],
        urls: res[:urls]
      }
    end

    def get_with_cache(url)
      # 「件数取得」と「検索結果取得」で2回同じ検索が行われるのでキャッシュしておく
      Rails.cache.fetch Digest::MD5.hexdigest(url), expires_in: 1.day do
        open(url).read
      end
    end

    def get_stanzas(stanza_endpoint)
      stanza_endpoint.reject {|key| key == 'url' }.values.flatten
    end
  end
end
