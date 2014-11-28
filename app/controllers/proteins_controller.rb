class ProteinsController < ApplicationController

  def search(environment, taxonomy, biological_process, molecular_function, cellular_component, phenotype, iDisplayLength, iDisplayStart)
    # todo: order
    @args = {
      meo_id: environment,
      tax_id: taxonomy,
      bp_id: biological_process,
      mf_id: molecular_function,
      cc_id: cellular_component,
      mpo_id: phenotype
    }

    @hits_count = Protein.count(@args).to_i

    respond_to do |format|
      format.json do
        proteins = Protein.search(@args.merge(limit: iDisplayLength, offset: iDisplayStart))

        @sEcho       = params[:sEcho].to_i
        @proteins    = proteins
        @total_count = Protein.count
      end

      format.csv do
        @streaming = true
        @filename = "togo_genome-environment-#{environment.split('/').last}-taxonomy-#{taxonomy.split('/').last}-biological_process-#{biological_process.split('/GO_').last}-molecular_function-#{molecular_function.split('/GO_').last}-cellular_component-#{cellular_component.split('/GO_').last}-phenotype-#{phenotype.split('#').last}.csv"
      end
    end
  end
end
