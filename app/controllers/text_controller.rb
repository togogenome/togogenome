class TextController < ApplicationController
  before_filter :search_multiple_target, only: :search_stanza, if: :multiple_target?

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

  def search_multiple_target
    redirect_to search_text_index_path(target: params[:target], q: params[:q])
  end
end
