class PhenotypeController < ApplicationController
  def show(id)
    @phenotype_id = id
    @phenotype = Phenotype.find(id)
  end
end
