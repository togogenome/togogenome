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
      stanza_data = Stanza.all.find {|s| s['id'] == stanza_id }

      result = get_with_cache(stanza_id, q)

      {
        enabled:     result.present?,
        urls:        (result ? result['response']['docs'].map {|doc| doc['@id']} : []),
        count:       (result ? result['response']['numFound'] : 0),
        stanza_id:   stanza_id,
        stanza_name: stanza_data['name'],
        report_type: stanza_data['report_type']
      }
    end

    def searchable?(stanza_id)
      # 検索可能なスタンザか否かを返す。
      # プロバイダーに所属する各スタンザが、テキスト検索に対応しているか否かを取得する仕組みが無いため
      # ハードコードしている
      %w(environment_attributes).include?(stanza_id)
    end

    private

    def get_with_cache(stanza_id, q)
      begin
        # 「件数取得」と「検索結果取得」で2回同じ検索が行われるのでキャッシュしておく
        Rails.cache.fetch Digest::MD5.hexdigest(stanza_id + q), expires_in: 1.day, compress: true do
          solr = RSolr.connect(url: "#{Endpoint.fulltextsearch}/#{stanza_id}")
          # とりあえず 100件まで取得としているが、Solr側でページングの機能があるのでそれを使うように対応したい
          solr.get 'select', params: {q: q, rows: 100}
        end
      rescue RSolr::Error::Http => e
        case e.response[:status]
        when 404
          nil
        when 400...500
          raise 'Could not full-text search in your query. Please request again by changing the query.'
        else
          raise 'Full-text search server is down ...'
        end
      end
    end
  end
end
