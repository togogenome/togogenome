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
    stanza_id = URI(stanza_url).path.split('/').last
    # XXX id に対応する stanza が見つからなかったら落ちる
    stanza_name = Stanza.providers.togostanza.reject {|key, val| key == 'url' }.flat_map {|key, val| val }.find {|e| e['id'] == stanza_id }['name']
    @result = TextSearch.search_stanza(stanza_name, stanza_url, q)
  end
end
