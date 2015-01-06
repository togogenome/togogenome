module ReportType
  class Gene < Base
    class << self
      def addition_information(results)
        upids  = results.map {|b| "<#{b[:uniprot_id]}>" }.uniq.join(' ')
        uniport_ups = results.map {|b| "<#{b[:uniprot_up]}>" }.uniq.join(' ')
        taxids = results.map {|b| "<#{b[:taxonomy_id]}>" }.uniq.join(' ')

        sparqls = [
          find_genes_sparql(upids),
          find_gene_ontologies_sparql(uniport_ups)
        ]

        genes, gos = Parallel.map(sparqls, in_threads: 2) {|sparql|
          query(sparql)
        }

        results.map do |result|
          select_genes      = genes.select {|g| g[:uniprot_id] == result[:uniprot_id] }
          select_gos        = gos.select {|g| g[:uniprot_up] == result[:uniprot_up] }

          new(result, select_genes, select_gos)
        end
      end
    end

    def initialize(up_tax, genes, gos)
      @uniprot_taxonomy, @genes, @gos = up_tax, genes, gos
    end
  end
end
