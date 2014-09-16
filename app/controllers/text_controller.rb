class TextController < ApplicationController
  before_filter :redirect_to_search, only: %i(search_stanza), if: :all_or_reports?
  before_filter :redirect_to_search_stanza, only: %i(search), unless: :all_or_reports?

  def index
  end

  def search(q, target)
    begin
      @q = q
      @stanzas = TextSearch.search(q, target)
    rescue => ex
      @error = ex
    ensure
      render 'index'
    end
  end

  def search_stanza(q, target)
    @q = q
    result = TextSearch.search_by_stanza_id(q, target)

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
      %w(all gene_reports organism_reports environment_reports).include? params[:target]
  end

  def redirect_to_search_stanza
    redirect_to action: :search_stanza, target: params[:target], q: params[:q]
  end

  def redirect_to_search
    redirect_to action: :search, target: params[:target], q: params[:q]
  end
end
