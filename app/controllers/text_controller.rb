class TextController < ApplicationController
  def index
  end

  def search(q, target)
    begin
      @q = q
      result = TextSearch.search(q, target)

      @stanzas_group_by_report_type = result.group_by {|e| e[:report_type] }

      stanzas = result.flat_map {|stanza|
        stanza[:urls].map {|url|
          stanza.slice(:report_type, :stanza_url).merge(
            {stanza_query: Rack::Utils.parse_query(URI(url).query)}
          )
        }
      }
      @stanzas = Kaminari.paginate_array(stanzas).page(params[:page]).per(10)
    rescue StandardError => ex
      @error = ex
    ensure
      render 'index'
    end
  end
end
