class TextController < ApplicationController
  def index
  end

  def search(q)
    begin
      @result = TextSearch.search(q)
    rescue StandardError => ex
      @error = ex
    ensure
      render 'index'
    end
  end

  def search_stanza(id, q)
    stanza_url = id
    render text: TextSearch.search_stanza('No Name', stanza_url, q)
  end
end
