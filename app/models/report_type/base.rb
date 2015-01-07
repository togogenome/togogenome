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
        raise "Called abstract method"
      end
    end
  end
end
