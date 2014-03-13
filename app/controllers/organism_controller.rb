class OrganismController < ApplicationController
  def show(id)
    @taxonomic_id = id
  end
end
