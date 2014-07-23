class TextController < ApplicationController
  def index
  end

  def search(sequence)
    begin
      @result = TextSearch.search(params[:q])
    rescue StandardError => ex
      @error = ex
    ensure
      render 'index'
    end
  end
end
