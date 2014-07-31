require 'open-uri'

class TextSearch
  class << self
    def search(q)
      # [togostanza] の [organisms] のスタンザを検索
      stanza_root = Stanza.providers.togostanza.url
      name_and_urls = Stanza.providers.togostanza.organisms.map {|stanza|
        {name: stanza.name, url: "#{stanza_root}/#{stanza.id}"}
      }
      name_and_urls.map {|e|
        search_stanza(e[:name], e[:url], q)
      }.reject {|e|
        e[:enabled] == false
      }
      # [
      #   {
      #     name: 'stanza_name',
      #     stanza_url: 'http://example.com/stanza/hoge',
      #     enabled: true,
      #     count: 0,
      #     urls: []
      #   },
      #   {
      #     name: 'stanza_name',
      #     stanza_url: 'http://example.com/stanza/hoge',
      #     enabled: true,
      #     count: 0,
      #     urls: []
      #   }
      # ]
    end

    def search_stanza(stanza_name, stanza_url, q)
      url = "#{stanza_url}/text_search?q=#{q}"
      res = JSON.parse(open(url).read).with_indifferent_access
      {
        name: stanza_name,
        stanza_url: stanza_url,
        enabled: res[:enabled],
        count: res[:count],
        urls: res[:urls]
      }
    end
  end
end
