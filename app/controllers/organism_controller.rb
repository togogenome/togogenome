class OrganismController < ApplicationController
  def show(id)
    @taxonomic_id = id
    @organism = Organism.find(id)
  end
end
