module ReportType
  class Organism < Base
    class << self
      def count(meo_id: '', tax_id: '', bp_id: '', mf_id: '', cc_id: '', mpo_id: '')
        select_clause =  "SELECT COUNT(DISTINCT ?taxonomy_id) AS ?hits_count"
        sparql = build_organism_sparql(meo_id, tax_id, bp_id, mf_id, cc_id, mpo_id, select_clause)

        results = query(sparql)

        results.first[:hits_count]
      end

      def search(meo_id: '', tax_id: '', bp_id: '', mf_id: '', cc_id: '', mpo_id: '', limit: 25, offset: 0)
        select_clause, order_clause = "SELECT DISTINCT ?taxonomy_id ?taxonomy_name", 'ORDER BY ?taxonomy_name'
        sparql = build_organism_sparql(meo_id, tax_id, bp_id, mf_id, cc_id, mpo_id, select_clause, order_clause, limit, offset)

        results = query(sparql)

        return [] if results.empty?

        taxids = results.map {|b| "<#{b[:taxonomy_id]}>" }.uniq.join(' ')

        sparqls = [
          find_environments_sparql(PREFIX, ONTOLOGY, taxids),
          find_phenotypes_sparql(PREFIX, ONTOLOGY, taxids),
          find_genome_stats_sparql(PREFIX, ONTOLOGY, taxids)
        ]

        envs, phenotypes, stats = Parallel.map(sparqls, in_threads: 4) {|sparql|
          query(sparql)
        }

        results.map do |result|
          select_envs       = envs.select {|e| e[:taxonomy_id] == result[:taxonomy_id] }
          select_phenotypes = phenotypes.select {|p| p[:taxonomy_id] == result[:taxonomy_id] }
          select_stat       = stats.select {|s| s[:taxonomy_id] == result[:taxonomy_id] }.first

          new(result, select_envs, select_phenotypes, select_stat)
        end
      end
    end

    def initialize(up_tax, envs, phenotypes, stat)
      @uniprot_taxonomy, @envs, @phenotypes, @stat = up_tax, envs, phenotypes, stat
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
      @phenotypes.group_by {|p| p[:top_mpo_name]}.each_with_object({}) {|(top_name, phenotypes), hash|
        hash[top_name] = phenotypes.map {|phenotype| Struct.new(:id, :name).new(phenotype[:mpo_id], phenotype[:mpo_name]) }
      }
    end

    def stat
      return nil unless @stat
      Struct.new(:genome_size, :gene_num, :rrna_num, :trna_num, :ncrna_num)
      .new(@stat[:genome_size], @stat[:gene_num], @stat[:rrna_num], @stat[:trna_num], @stat[:ncrna_num])
    end
  end
end
