require 'open-uri'

class TextSearch
  class << self
    def search(q, target='all')
      # XXX nanostanza は検索してない
      search_targets(target).map {|id|
        search_by_stanza_id(q, id)
      }.reject {|e|
        e[:enabled] == false
      }
    end

    def search_by_stanza_id(q, stanza_id)
      stanza_url = "#{Stanza.providers.togostanza.url}/#{stanza_id}"
      url = "#{stanza_url}/text_search?q=#{q}"

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

    private

    def get_with_cache(url)
      # 「件数取得」と「検索結果取得」で2回同じ検索が行われるのでキャッシュしておく
      Rails.cache.fetch Digest::MD5.hexdigest(url), expires_in: 1.day, compress: true do
        open(url).read
      end
    end

    def search_targets(key)
      case key
      when 'all'
        Stanza.ids
      when 'gene_reports'
        Stanza.gene_ids
      when 'organism_reports'
        Stanza.organism_ids
      when 'environment_reports'
        Stanza.env_ids
      else
        [key]
      end
    end
  end
end
