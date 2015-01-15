class SequenceController < ApplicationController
  def index
  end

  def search(fragment)
    @sequences = Sequence.search(fragment.delete("\s\n"))
  rescue => ex
    @error = ex
  ensure
    render 'index'
  end
end
