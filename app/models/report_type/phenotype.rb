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
          #find_phenotype_inhabitants_stats_sparql(PREFIX, ONTOLOGY, mpos)
        ]

        #mpo_roots, mpo_inhabitants_stats = Parallel.map(sparqls, in_threads: 4) {|sparql|
        #  query(sparql)
        #}
        mpo_roots = query(sparqls.first)

        results.map do |result|
          select_mpo_roots = mpo_roots.select {|r| r[:mpo_id] == result[:mpo_id] }
          #select_mpo_inhabitants_stats = mpo_inhabitants_stats.select {|r| r[:mpo_id] == result[:mpo_id] }
          #new(result, select_mpo_roots, select_mpo_inhabitants_stats)
          new(result, select_mpo_roots)
        end
      end
    end

    def initialize(mpo, mpo_roots)
      @phenotype, @phenotype_roots = mpo, mpo_roots
    end

    def phenotype
      root_name = @phenotype_roots.empty? ? nil : @phenotype_roots.first[:name]

      Struct.new(:uri, :name, :root){
        def id
          uri.split('#').last
        end

        def inhabitants
          'todo'
        end
      }.new(@phenotype[:mpo_id], @phenotype[:mpo_name], root_name)
    end
  end
end
