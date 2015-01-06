module ReportType
  class Base
    include Queryable
    include SparqlBuilder

    class << self
      def count(meo_id: '', tax_id: '', bp_id: '', mf_id: '', cc_id: '', mpo_id: '')
        sparql  = build_sparql(self.to_s.demodulize, 'count', meo_id, tax_id, bp_id, mf_id, cc_id, mpo_id)
        results = query(sparql)

        results.first[:hits_count]
      end

      def search(meo_id: '', tax_id: '', bp_id: '', mf_id: '', cc_id: '', mpo_id: '', limit: 25, offset: 0)
        sparql  = build_sparql(self.to_s.demodulize, 'search', meo_id, tax_id, bp_id, mf_id, cc_id, mpo_id, limit, offset)
        results = query(sparql)

        return [] if results.empty?

        addition_information(results)
      end

      def addition_information(results)
        upids  = results.map {|b| "<#{b[:uniprot_id]}>" }.uniq.join(' ')
        uniport_ups = results.map {|b| "<#{b[:uniprot_up]}>" }.uniq.join(' ')
        taxids = results.map {|b| "<#{b[:taxonomy_id]}>" }.uniq.join(' ')

        sparqls = [
          find_genes_sparql(upids),
          find_gene_ontologies_sparql(uniport_ups),
          find_environments_sparql(taxids),
          find_phenotypes_sparql(taxids)
        ]

        genes, gos, envs, phenotypes = Parallel.map(sparqls, in_threads: 4) {|sparql|
          query(sparql)
        }

        results.map do |result|
          select_genes      = genes.select {|g| g[:uniprot_id] == result[:uniprot_id] }
          select_gos        = gos.select {|g| g[:uniprot_up] == result[:uniprot_up] }
          select_envs       = envs.select {|e| e[:taxonomy_id] == result[:taxonomy_id] }
          select_phenotypes = phenotypes.select {|p| p[:taxonomy_id] == result[:taxonomy_id] }

          new(result, select_genes, select_gos, select_envs, select_phenotypes)
        end
      end
    end

    def initialize(up_tax, genes, gos, envs, phenotypes)
      @uniprot_taxonomy, @genes, @gos, @envs, @phenotypes = up_tax, genes, gos, envs, phenotypes
    end

    def id; @uniprot_taxonomy[:uniprot_id].split('/').last; end

    def uri; @uniprot_taxonomy[:uniprot_id]; end

    def uniprot; @uniprot_taxonomy[:uniprot_up]; end

    def name; @uniprot_taxonomy[:recommended_name]; end

    def tax
      Struct.new(:uri, :name) {
        def id
          uri.split('/').last
        end
      }.new(@uniprot_taxonomy[:taxonomy_id], @uniprot_taxonomy[:taxonomy_name])
    end

    def genes
      @genes.map {|gene|
        Struct.new(:togogenome_uri) {
          def id
            togogenome_uri.split('/').last
          end
        }.new(gene[:togogenome])
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
