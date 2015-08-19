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

    def search_by_stanza_id(q, stanza_id, page = 1)
      stanza_data = Stanza.all.find {|s| s['id'] == stanza_id }
      result = get_with_cache(stanza_id, q, page)
      {
        enabled:     result.present?,
        urls:        (result ? result['response']['docs'].map {|doc| doc['@id']} : []),
        count:       (result ? result['response']['numFound'] : 0),
        stanza_id:   stanza_id,
        stanza_name: stanza_data['name'],
        report_type: stanza_data['report_type']
      }
    end

    private

    def get_with_cache(stanza_id, q, page)
      begin
        solr = RSolr.connect(url: "#{Endpoint.fulltextsearch}/#{stanza_id}")
        solr.paginate(page, PAGINATE[:per_page], 'select', params: {q: q})
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
