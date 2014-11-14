class StanzaViewController < ApplicationController
  def index
  end

  def search(q, category)
    if all_or_reports?(category)
      count(q, category)
    else
      list(q, category)
    end
  end

  private

  def all_or_reports?(category)
    %w(all gene_reports organism_reports environment_reports).include? category
  end

  def count(q, category)
    @q = q
    @stanzas = TextSearch.search_by_category(q, category)
  rescue => ex
    @error = ex
  ensure
    render 'index'
  end

  def list(q, stanza_id)
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

    render 'list'
  end
end
