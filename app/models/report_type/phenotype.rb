module ReportType
  class Phenotype < Base
    include SparqlBuilder::Phenotype

    class << self
      def count(meo_id: '', tax_id: '', bp_id: '', mf_id: '', cc_id: '', mpo_id: '')
        select_clause =  "SELECT COUNT(DISTINCT ?mpo_id) AS ?hits_count"
        sparql = build_sparql(meo_id, tax_id, bp_id, mf_id, cc_id, mpo_id, select_clause)

        results = query(sparql)

        results.first[:hits_count]
      end

      def search(meo_id: '', tax_id: '', bp_id: '', mf_id: '', cc_id: '', mpo_id: '', limit: 25, offset: 0)
        select_clause, order_clause = "SELECT DISTINCT ?mpo_id ?mpo_name ?category ?category_name", "ORDER BY ?category_name"
        sparql = build_sparql(meo_id, tax_id, bp_id, mf_id, cc_id, mpo_id, select_clause, order_clause, limit, offset)

        results = query(sparql)

        return [] if results.empty?

        mpos = results.map {|r| "<#{r[:mpo_id]}>" }.uniq.join(' ')

        sparql = find_phenotype_inhabitants_sparql(PREFIX, ONTOLOGY, mpos)

        inhabitants = query(sparql)

        results.map do |result|
          select_inhabitants = inhabitants.find {|r| r[:mpo_id] == result[:mpo_id] }

          new(result, select_inhabitants)
        end
      end
    end

    def initialize(mpo, inhabitants)
      @phenotype, @inhabitants = mpo, inhabitants
    end

    def phenotype
      OpenStruct.new(
        uri:         @phenotype[:mpo_id],
        name:        @phenotype[:mpo_name],
        category:    @phenotype[:category_name],
        id:          @phenotype[:mpo_id].split('#').last,
        inhabitants: @inhabitants.try(:[], :inhabitants)
      )
    end
  end
end
