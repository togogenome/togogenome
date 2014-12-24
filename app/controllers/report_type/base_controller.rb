class ReportType::BaseController < ApplicationController
  def index(environment, taxonomy, biological_process, molecular_function, cellular_component, phenotype, length, start)
    # todo: order
    @args = {
      meo_id: environment,
      tax_id: taxonomy,
      bp_id:  biological_process,
      mf_id:  molecular_function,
      cc_id:  cellular_component,
      mpo_id: phenotype
    }

    klass = controller_path.classify.constantize

    @hits_count = klass.count(@args).to_i

    respond_to do |format|
      format.json do
        @results     = klass.search(@args.merge(limit: length, offset: start))
        @total_count = klass.count
      end

      format.csv do
        @streaming = true
        @filename = "togo_genome-environment-#{environment.split('/').last}-taxonomy-#{taxonomy.split('/').last}-biological_process-#{biological_process.split('/GO_').last}-molecular_function-#{molecular_function.split('/GO_').last}-cellular_component-#{cellular_component.split('/GO_').last}-phenotype-#{phenotype.split('#').last}.csv"
      end
    end
  end
end
