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
          name: name,
          enabled: res[:enabled],
          count: res[:count],
          urls: res[:urls]
        }
      }.reject {|e|
        e[:enabled] == false
      }
    end
  end
end
