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

        targets = [
          { name: 'envs',       sparql: find_environments_sparql( results.map {|b| "<#{b[:taxonomy_id]}>" }.uniq.join(' ') ) },
          { name: 'phenotypes', sparql: find_phenotypes_sparql( results.map {|b| "<#{b[:taxonomy_id]}>" }.uniq.join(' ') ) }
        ]


        envs, phenotypes = nil, nil

        Parallel.map(targets, in_threads: 4) {|target|
          res = query(target[:sparql])
          case target[:name]
          when 'envs'       then envs = res
          when 'phenotypes' then phenotypes = res
          end
        }

        results.map do |result|
          select_envs       = envs.select {|e| e[:taxonomy_id] == result[:taxonomy_id] }
          select_phenotypes = phenotypes.select {|p| p[:taxonomy_id] == result[:taxonomy_id] }

          new(result, select_envs, select_phenotypes)
        end
      end
    end

    def initialize(up_tax, envs, phenotypes)
      @tax = ::Taxonomy.new(up_tax[:taxonomy_id], up_tax[:taxonomy_name])
      @envs       = envs.map {|env| ::Environment.new(env[:meo_id], env[:meo_name]) }
      @phenotypes = phenotypes.map {|phenotype| ::Phenotype.new(phenotype[:mpo_id], phenotype[:mpo_name]) }
    end

    attr_reader :tax, :envs, :phenotypes
  end
end
