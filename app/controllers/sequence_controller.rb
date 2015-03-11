class SequenceController < ApplicationController
  def index
  end

  def search(fragment)
    sequence   = fragment.delete("\s\n")
    @genomes   = Sequence::Genome.search(sequence)
    @organisms = Sequence::Organism.search(sequence)
  rescue Sequence::GggenomeSearchError => ex
    @error = ex
  rescue  => ex
    @error = '[Server Error] Please contact the site administrator .'
    Rails.logger.error ex
  ensure
    render 'index'
  end
end
