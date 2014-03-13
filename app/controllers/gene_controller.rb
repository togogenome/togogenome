class GeneController < ApplicationController
  def show(id)
    # "1148:slr1311" で1つのid
    @taxonomic_id, @locus_tag = id.split(':')
  end
end
