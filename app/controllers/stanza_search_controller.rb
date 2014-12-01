class StanzaSearchController < ApplicationController
  def index(q, category)
    @q = q
    @stanzas = TextSearch.search_by_category(@q, category)
  rescue => ex
    @error = ex
  end

  def show(q, stanza_id)
    @q = q
    result = TextSearch.search_by_stanza_id(q, stanza_id)

    stanzas = result['urls'].map {|url|
      {
        stanza_query: Rack::Utils.parse_query(URI(url).query),
        report_type:  result[:report_type],
        stanza_url:   result[:stanza_url]
      }
    }

    @stanzas = Kaminari.paginate_array(stanzas).page(params[:page]).per(TextSearch::PAGINATE[:per_page])
  end
end
