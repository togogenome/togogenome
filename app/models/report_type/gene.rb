module ReportType
  class Gene < Base
    class << self
      def count(meo_id: '', tax_id: '', bp_id: '', mf_id: '', cc_id: '', mpo_id: '')
        select_clause =  "SELECT COUNT(DISTINCT ?togogenome) AS ?hits_count"
        sparql = build_gene_sparql(@@prefix, @@ontology, meo_id, tax_id, bp_id, mf_id, cc_id, mpo_id, select_clause)

        results = query(sparql)

        results.first[:hits_count]
      end

      def search(meo_id: '', tax_id: '', bp_id: '', mf_id: '', cc_id: '', mpo_id: '', limit: 25, offset: 0)
        select_clause = "SELECT DISTINCT ?togogenome ?taxonomy_id ?taxonomy_name"
        sparql = build_gene_sparql(@@prefix, @@ontology, meo_id, tax_id, bp_id, mf_id, cc_id, mpo_id, select_clause, limit, offset)

        results = query(sparql)

        return [] if results.empty?

        genes = results.map {|b| "<#{b[:togogenome]}>" }.uniq.join(' ')

        sparqls = [
          find_proteins_sparql(@@prefix, @@ontology, genes),
          find_gene_ontologies_sparql(@@prefix, @@ontology, genes)
        ]

        proteins, gos = Parallel.map(sparqls, in_threads: 4) {|sparql|
          query(sparql)
        }

        results.map do |result|
          select_proteins = proteins.select {|p| p[:gene] == result[:togogenome] }
          select_gos = gos.select {|g| g[:gene] == result[:togogenome] }
          new(result, select_proteins, select_gos)
        end
      end
    end

    def initialize(gene_and_taxonomy, select_proteins, select_gos)
      @gene_and_taxonomy, @proteins, @gos = gene_and_taxonomy, select_proteins, select_gos
    end

    def gene_and_taxonomy
      Struct.new(:gene_uri, :taxonomy, :taxonomy_name) {
        def taxonomy_id
          taxonomy.split('/').last
        end

        def gene_id
          gene_uri.split('/').last
        end
      }.new(@gene_and_taxonomy[:togogenome], @gene_and_taxonomy[:taxonomy_id], @gene_and_taxonomy[:taxonomy_name])
    end

    def proteins
      @proteins.map {|protein|
        Struct.new(:uri, :uniprot_link, :name) {
          def id
            uri.split('/').last
          end
        }.new(protein[:uniprot_id], protein[:uniprot_up], protein[:recommended_name])
      }
    end

    def gos
      @gos.map {|go|
        Struct.new(:uri, :name) {
          def id
            uri.split('id=').last
          end
        }.new(go[:quick_go_uri], go[:go_name])
      }
    end
  end
end
