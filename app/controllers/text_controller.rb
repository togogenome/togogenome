class TextController < ApplicationController
  def index
  end

  def search(q)
    begin
      @q = q
      @result = TextSearch.search(q)
    rescue StandardError => ex
      @error = ex
    ensure
      render 'index'
    end
  end

  def search_stanza(id, q)
    stanza_url = id
    @result = TextSearch.search_stanza('No Name', stanza_url, q)
  end
end
