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
      # とりあえず 100件まで取得としているが、Solr側でページングの機能があるのでそれを使うように対応したい
      url = "#{Endpoint.fulltextsearch}/#{stanza_id}/select?q=#{URI.encode_www_form_component(q)}&wt=json&&rows=100"

      stanza_data = Stanza.all.find {|s| s['id'] == stanza_id }

      result = JSON.parse(get_with_cache(url))

      {
        enabled:     result.present?,
        urls:        (result['response'].try {|r| r['docs'].map {|doc| doc['@id']} } || []),
        count:       (result['response'].try {|r| r['numFound'] } || 0),
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

    def get_with_cache(url)
      begin
        # 「件数取得」と「検索結果取得」で2回同じ検索が行われるのでキャッシュしておく
        Rails.cache.fetch Digest::MD5.hexdigest(url), expires_in: 1.day, compress: true do
          open(url).read
        end
      rescue OpenURI::HTTPError => e
        code, _message = e.io.status

        case code.to_i
        when 404
          '{}'
        when 400...500
          raise 'Could not full-text search in your query. Please request again by changing the query.'
        else
          raise 'Full-text search server is down ...'
        end
      end
    end
  end
end
