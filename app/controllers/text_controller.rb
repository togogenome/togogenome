class TextController < ApplicationController
  before_filter :redirect_to_search, only: %i(search_stanza), if: :all_or_reports?
  before_filter :redirect_to_search_stanza, only: %i(search), unless: :all_or_reports?

  def index
  end

  def search(q, category)
    @q = q
    @stanzas = TextSearch.search(q, category)
  rescue => ex
    @error = ex
  ensure
    render 'index'
  end

  def search_stanza(q, category)
    @q = q
    result = TextSearch.search_by_stanza_id(q, category)

    stanzas = result['urls'].map {|url|
      {
        stanza_query: Rack::Utils.parse_query(URI(url).query),
        report_type:  result[:report_type],
        stanza_url:   result[:stanza_url]
      }
    }

    @stanzas = Kaminari.paginate_array(stanzas).page(params[:page]).per(TextSearch::PAGINATE[:per_page])
  end

  private

  def all_or_reports?
      %w(all gene_reports organism_reports environment_reports).include? params[:category]
  end

  def redirect_to_search_stanza
    redirect_to action: :search_stanza, category: params[:category], q: params[:q]
  end

  def redirect_to_search
    redirect_to action: :search, category: params[:category], q: params[:q]
  end
end
