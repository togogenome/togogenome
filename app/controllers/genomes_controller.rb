class GenomesController < ApplicationController
  def index
  end

  def search(sequence)
    begin
      @genomes = Genome.search(sequence.delete("\s\n"))
    rescue StandardError => ex
      @error = ex
    ensure
      render 'index'
    end
  end
end
