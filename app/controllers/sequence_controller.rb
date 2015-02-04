class SequenceController < ApplicationController
  def index
  end

  def search(fragment)
    gggenome_response = Sequence.search_gggenome(fragment.delete("\s\n"))
    @sequences = Sequence.append_sequence_ontologies(gggenome_response)
    @organisms = Sequence.append_organisms(gggenome_response)
  rescue => ex
    @error = ex
  ensure
    render 'index'
  end
end
