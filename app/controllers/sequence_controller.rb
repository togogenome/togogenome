class SequenceController < ApplicationController
  def index
  end

  def search(fragment)
    sequence   = fragment.delete("\s\n")
    @genomes   = Sequence::Genome.search(sequence)
    @organisms = Sequence::Organism.search(sequence)
  rescue => ex
    @error = ex
  ensure
    render 'index'
  end
end
