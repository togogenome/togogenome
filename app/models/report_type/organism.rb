module ReportType
  class Organism < Base
    class << self
      def count(meo_id: '', tax_id: '', bp_id: '', mf_id: '', cc_id: '', mpo_id: '')
        select_clause =  "SELECT COUNT(DISTINCT ?taxonomy_id) AS ?hits_count"
        sparql = build_organism_sparql(@@prefix, @@ontology, meo_id, tax_id, bp_id, mf_id, cc_id, mpo_id, select_clause)

        results = query(sparql)

        results.first[:hits_count]
      end

      def search(meo_id: '', tax_id: '', bp_id: '', mf_id: '', cc_id: '', mpo_id: '', limit: 25, offset: 0)
        select_clause, order_clause = "SELECT DISTINCT ?taxonomy_id ?taxonomy_name", 'ORDER BY ?taxonomy_name'
        sparql = build_organism_sparql(@@prefix, @@ontology, meo_id, tax_id, bp_id, mf_id, cc_id, mpo_id, select_clause, order_clause, limit, offset)

        results = query(sparql)

        return [] if results.empty?

        taxids = results.map {|b| "<#{b[:taxonomy_id]}>" }.uniq.join(' ')

        sparqls = [
          find_environments_sparql(@@prefix, @@ontology, taxids),
          find_phenotypes_sparql(@@prefix, @@ontology, taxids),
          #find_refseqs_sparql(@@prefix, @@ontology, taxids),
          find_genome_stats_sparql(@@prefix, @@ontology, taxids)
        ]

        envs, phenotypes, stats = Parallel.map(sparqls, in_threads: 4) {|sparql|
          query(sparql)
        }

        # https://github.com/togostanza/togostanza/blob/master/organism_gc_nano_stanza/stanza.rb
        #
        # gc_percent_arr = refseqs.group_by {|r| r[:taxonomy_id] }.map {|taxonomy_id, refs|
        #   seqs = Parallel.map(refs, in_threads: 4) {|ref|
        #     seq = open("http://togows.org/entry/nucleotide/#{ref[:refseq]}/seq").read
        #     [seq.count('a') + seq.count('t'), seq.count('g') + seq.count('c')]
        #   }
        #
        #   at = seqs.map(&:first).inject {|sum, n| sum + n }
        #   gc = seqs.map(&:last).inject {|sum, n| sum + n }
        #   gc_percent = (gc.to_f / (at + gc).to_f * 100.0).to_i
        #
        #   {taxonomy_id: taxonomy_id, gc_percent: gc_percent}
        # }

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

      Struct.new(:gene_num, :rrna_num, :trna_num, :ncrna_num, :project_num) {
        def gene_num_per_project_num
          (gene_num.to_f / project_num.to_f).round
        end

        def rrna_num_per_project_num
          (rrna_num.to_f / project_num.to_f).round
        end

        def trna_num_per_project_num
          (trna_num.to_f / project_num.to_f).round
        end

        def ncrna_num_per_project_num
          (ncrna_num.to_f / project_num.to_f).round
        end
      }.new(@stat[:gene_num], @stat[:rrna_num], @stat[:trna_num], @stat[:ncrna_num], @stat[:project_num])
    end
  end
end
