# coding: utf-8

module Proteins
  class Organism < ::Protein
    class << self
      def count(meo_id: '', tax_id: '', bp_id: '', mf_id: '', cc_id: '', mpo_id: '')
        sparql  = organism_count_sparql(meo_id, tax_id, bp_id, mf_id, cc_id, mpo_id)
        results = query(sparql)

        results.first[:hits_count]
      end

      def search(meo_id: '', tax_id: '', bp_id: '', mf_id: '', cc_id: '', mpo_id: '', limit: 25, offset: 0)
        sparql  = organism_search_sparql(meo_id, tax_id, bp_id, mf_id, cc_id, mpo_id, limit, offset)
        results = query(sparql)

        return [] if results.empty?

        results.map do |result|
          new(result)
        end
      end
    end

    def initialize(up_tax)
      @tax = Taxonomy.new(up_tax[:taxonomy_id], up_tax[:taxonomy_name])
    end

    attr_reader :tax
  end
end
