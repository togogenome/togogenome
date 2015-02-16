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
      count     = @meo_inhabitants_stats.empty? ? nil : @meo_inhabitants_stats.first[:count]

      Struct.new(:uri, :name, :category, :inhabitants){
        def id
          uri.split('/').last
        end
      }.new(@environment[:meo_id], @environment[:meo_name], @environment[:category_name], count)
    end
  end
end
