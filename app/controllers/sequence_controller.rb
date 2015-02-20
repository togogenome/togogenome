class SequenceController < ApplicationController
  def index
  end

  def search(fragment)
    sequence = fragment.delete("\s\n")
    @sequences = Sequence.search_sequence_ontologies(sequence)
    @organisms = Sequence.search_organisms(sequence)
  rescue => ex
    @error = ex
  ensure
    render 'index'
  end
end
