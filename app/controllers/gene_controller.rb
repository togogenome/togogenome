class GeneController < ApplicationController
  def show(id)
    # "1148:slr1311" で1つのid
    @refseq_id, @gene_id = id.split(':')
    @gene = Gene.find(id)
  end
end
