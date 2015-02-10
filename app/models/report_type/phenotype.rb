module ReportType
  class Phenotype < Base
    class << self
      def count(meo_id: '', tax_id: '', bp_id: '', mf_id: '', cc_id: '', mpo_id: '')
        select_clause =  "SELECT COUNT(DISTINCT ?mpo_id) AS ?hits_count"
        sparql = build_phenotype_sparql(meo_id, tax_id, bp_id, mf_id, cc_id, mpo_id, select_clause)

        results = query(sparql)

        results.first[:hits_count]
      end

      def search(meo_id: '', tax_id: '', bp_id: '', mf_id: '', cc_id: '', mpo_id: '', limit: 25, offset: 0)
        select_clause = "SELECT DISTINCT ?mpo_id ?mpo_name"
        sparql = build_phenotype_sparql(meo_id, tax_id, bp_id, mf_id, cc_id, mpo_id, select_clause, limit, offset)

        results = query(sparql)

        return [] if results.empty?

        mpos = results.map {|r| "<#{r[:mpo_id]}>" }.uniq.join(' ')

        sparqls = [
          find_phenotype_root_sparql(PREFIX, ONTOLOGY, mpos),
          find_phenotype_inhabitants_sparql(PREFIX, ONTOLOGY, mpos)
        ]

        mpo_roots, mpo_inhabitants = Parallel.map(sparqls, in_threads: 4) {|sparql|
          query(sparql)
        }

        results.map do |result|
          select_mpo_roots = mpo_roots.select {|r| r[:mpo_id] == result[:mpo_id] }
          select_mpo_inhabitants = mpo_inhabitants.select {|r| r[:mpo_id] == result[:mpo_id] }
          new(result, select_mpo_roots, select_mpo_inhabitants)
        end
      end
    end

    def initialize(mpo, mpo_roots, inhabitants)
      @phenotype, @phenotype_roots, @inhabitants = mpo, mpo_roots, inhabitants
    end

    def phenotype
      OpenStruct.new(
        uri:  @phenotype[:mpo_id],
        name: @phenotype[:mpo_name],
        root: @phenotype_roots.first.try(:[], :name),
        id:   @phenotype[:mpo_id].split('#').last,
        inhabitants: @inhabitants.first.try(:[], :inhabitants)
      )
    end
  end
end
