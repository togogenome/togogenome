class PhenotypeController < ApplicationController
  def show(id)
    @phenotype_id = id

    render text: "hello, phenotype: #{@phenotype_id}"
  end
end
