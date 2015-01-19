class GeneController < ApplicationController
  def show(id)
    # "150340:NC_013456.1#feature:718674-719099:1:gene.715"
    #  => "150340", "NC_013456.1#feature:718674-719099:1:gene.715"
    @refseq_id, @gene_id = id.split(':', 2)
  end
end
