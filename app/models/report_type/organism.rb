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
      @uniprot_taxonomy, @envs, @phenotypes = up_tax, envs, phenotypes
    end

    def tax
      Struct.new(:uri, :name) {
        def id
          uri.split('/').last
        end
      }.new(@uniprot_taxonomy[:taxonomy_id], @uniprot_taxonomy[:taxonomy_name])
    end

    def envs
      @envs.map {|env|
        Struct.new(:id, :name).new(env[:meo_id], env[:meo_name])
      }
    end

    def phenotypes
      @phenotypes.map {|phenotype|
        Struct.new(:id, :name).new(phenotype[:mpo_id], phenotype[:mpo_name])
      }
    end
  end
end
