class StanzaSearchController < ApplicationController
  def index(q)
    @stanzas = StanzaSearch.search(q)
  rescue => ex
    @error = ex
  end

  def show(q, stanza_id)
    page = params[:page] || 1

    result = StanzaSearch.search_by_stanza_id(q, stanza_id, page)
    stanzas = result[:urls].map {|url|
      {
        togogenome_url: url,
        stanza_uri:     result[:stanza_uri],
        stanza_id:      result[:stanza_id],
        report_type:    result[:report_type],
        stanza_attr_id: url.split('/').last
      }
    }

    @stanzas = Kaminari.paginate_array(stanzas, total_count: result[:count]).page(page).per(StanzaSearch::PAGINATE[:per_page])
  end
end
