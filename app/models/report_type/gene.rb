module ReportType
  class Gene < Base
    include SparqlBuilder::Gene

    class << self
      def count(meo_id: '', tax_id: '', bp_id: '', mf_id: '', cc_id: '', mpo_id: '')
        select_clause =  "SELECT COUNT(DISTINCT ?togogenome) AS ?hits_count"
        sparql = build_base_sparql(meo_id, tax_id, bp_id, mf_id, cc_id, mpo_id, select_clause)

        results = query(sparql)

        results.first[:hits_count]
      end

      def search(meo_id: '', tax_id: '', bp_id: '', mf_id: '', cc_id: '', mpo_id: '', limit: 25, offset: 0)
        select_clause = "SELECT DISTINCT ?togogenome ?taxonomy_id ?taxonomy_name"
        sparql = build_base_sparql(meo_id, tax_id, bp_id, mf_id, cc_id, mpo_id, select_clause, limit, offset)

        results = query(sparql)

        return [] if results.empty?

        genes = results.map {|b| "<#{b[:togogenome]}>" }.uniq.join(' ')

        sparqls = [
          find_proteins_sparql(PREFIX, ONTOLOGY, genes),
          find_gene_ontologies_sparql(PREFIX, ONTOLOGY, genes)
        ]

        proteins, gos = Parallel.map(sparqls, in_threads: 4) {|sparql|
          query(sparql)
        }

        results.map do |result|
          select_proteins = proteins.select {|p| p[:gene] == result[:togogenome] }
          select_gos      = gos.select {|g| g[:gene] == result[:togogenome] }

          new(result, select_proteins, select_gos)
        end
      end
    end

    def initialize(gene_and_taxonomy, proteins, gos)
      @gene_and_taxonomy, @proteins, @gos = gene_and_taxonomy, proteins, gos
    end

    def gene_and_taxonomy
      togogenome, taxonomy, taxonomy_name = @gene_and_taxonomy.values_at(:togogenome, :taxonomy_id, :taxonomy_name)

      OpenStruct.new(
        togogenome:    togogenome,
        taxonomy:      taxonomy,
        taxonomy_name: taxonomy_name,
        taxonomy_id:   taxonomy.split('/').last,
        gene_id:       togogenome.split('/').last
      )
    end

    def proteins
      @proteins.map do |protein|
        OpenStruct.new(
          uri:          protein[:uniprot_id],
          uniprot_link: protein[:uniprot_up],
          name:         protein[:recommended_name],
          id:           protein[:uniprot_id].split('/').last
        )
      end
    end

    def gos
      @gos.map do |go|
        OpenStruct.new(
          uri:  go[:quick_go_uri],
          name: go[:go_name],
          id:   go[:quick_go_uri].split('id=').last
        )
      end
    end
  end
end
