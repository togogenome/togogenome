class SequenceController < ApplicationController
  def index
  end

  def search(fragment)
    begin
      @sequences = Sequence.search(fragment.delete("\s\n"))
    rescue StandardError => ex
      @error = ex
    ensure
      render 'index'
    end
  end
end
