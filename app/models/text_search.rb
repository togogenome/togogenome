require 'open-uri'

class TextSearch
  class << self
    def search(q)
      # [togostanza] の [organisms] のスタンザを検索
      stanza_root = Stanza.providers.togostanza.url
      name_and_urls = Stanza.providers.togostanza.organisms.map {|stanza|
        {name: stanza.name, url: "#{stanza_root}/#{stanza.id}/text_search?q=#{q}"}
      }
      name_and_urls.map {|e|
        name = e[:name]
        url = e[:url]
        res = JSON.parse(open(url).read).with_indifferent_access
        {
          name: "#{name} (#{res[:count]})",
          count: res[:count],
          urls: res[:urls]
        }
      }
      # [
      #   {
      #     name: 'stanza name',
      #     count: 3,
      #     urls: [
      #       'http://example.com/1',
      #       'http://example.com/2',
      #       'http://example.com/3'
      #     ]
      #   },
      #   {
      #     name: 'stanza name again',
      #     count: 0,
      #     urls: []
      #   }
      # ]
    end
  end
end
