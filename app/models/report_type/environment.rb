module ReportType
  class Environment < Base
    class << self
      def count(meo_id: '', tax_id: '', bp_id: '', mf_id: '', cc_id: '', mpo_id: '')
        select_clause =  "SELECT COUNT(DISTINCT ?meo_id) AS ?hits_count"
        sparql = build_environment_sparql(meo_id, tax_id, bp_id, mf_id, cc_id, mpo_id, select_clause)

        results = query(sparql)

        results.first[:hits_count]
      end

      def search(meo_id: '', tax_id: '', bp_id: '', mf_id: '', cc_id: '', mpo_id: '', limit: 25, offset: 0)
        select_clause, order_clause = "SELECT DISTINCT ?meo_id ?meo_name ?category ?category_name", "ORDER BY ?category_name"
        sparql = build_environment_sparql(meo_id, tax_id, bp_id, mf_id, cc_id, mpo_id, select_clause, order_clause, limit, offset)

        results = query(sparql)

        return [] if results.empty?

        meos = results.map {|r| "<#{r[:meo_id]}>" }.uniq.join(' ')

        sparql = find_environment_inhabitants_stats_sparql(PREFIX, ONTOLOGY, meos)

        meo_inhabitants_stats =  query(sparql)

        results.map do |result|
          select_meo_inhabitants_stats = meo_inhabitants_stats.select {|r| r[:meo_id] == result[:meo_id] }
          new(result, select_meo_inhabitants_stats)
        end
      end
    end

    def initialize(meo, meo_inhabitants_stats)
      @environment, @meo_inhabitants_stats = meo, meo_inhabitants_stats
    end

    def environment
      OpenStruct.new(
        uri:         @environment[:meo_id],
        name:        @environment[:meo_name],
        root:        @environment[:category_name],
        inhabitants: @meo_inhabitants_stats.first.try(:[], :count),
        id:          @environment[:meo_id].split('/').last
      )
    end
  end
end
