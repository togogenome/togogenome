module ReportType
  class Organism < Base
    class << self
      def addition_information(results)
        taxids = results.map {|b| "<#{b[:taxonomy_id]}>" }.uniq.join(' ')

        sparqls = [
          find_environments_sparql(taxids),
          find_phenotypes_sparql(taxids)
        ]

        envs, phenotypes = Parallel.map(sparqls, in_threads: 4) {|sparql|
          query(sparql)
        }

        results.map do |result|
          select_envs       = envs.select {|e| e[:taxonomy_id] == result[:taxonomy_id] }
          select_phenotypes = phenotypes.select {|p| p[:taxonomy_id] == result[:taxonomy_id] }

          new(result, select_envs, select_phenotypes)
        end
      end
    end

    def initialize(up_tax, envs, phenotypes)
      @tax        = Base::Taxonomy.new(up_tax[:taxonomy_id], up_tax[:taxonomy_name])
      @envs       = envs.map {|env| Base::Environment.new(env[:meo_id], env[:meo_name]) }
      @phenotypes = phenotypes.map {|phenotype| Base::Phenotype.new(phenotype[:mpo_id], phenotype[:mpo_name]) }
    end

    attr_reader :tax, :envs, :phenotypes
  end
end
