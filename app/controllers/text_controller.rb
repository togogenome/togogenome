class TextController < ApplicationController
  before_filter :search_multiple_target, only: %i(search_stanza), if: :multiple_target?
  before_filter :search_single_target, only: %i(search), unless: :multiple_target?

  def index
  end

  def search(q, target)
    begin
      @q = q
      @stanzas = TextSearch.search(q, target)
    rescue StandardError => ex
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

    @stanzas = Kaminari.paginate_array(stanzas).page(params[:page]).per(10)
  end

  private
  def multiple_target?
    %w(all gene_reports organism_reports environment_reports).include?(params[:target])
  end

  def search_single_target
    redirect_to action: :search_stanza, target: params[:target], q: params[:q]
  end

  def search_multiple_target
    redirect_to action: :search, target: params[:target], q: params[:q]
  end
end
