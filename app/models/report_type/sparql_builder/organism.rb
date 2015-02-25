require 'erb'
require 'sparql_util'

module ReportType
  module SparqlBuilder
    module Organism
      extend ActiveSupport::Concern

      module ClassMethods
        include SPARQLUtil

        def build_sparql(meo_id, tax_id, bp_id, mf_id, cc_id, mpo_id, select_clause, order_clause = '', limit = 1, offset = 0)
          if [bp_id, mf_id, cc_id].any?(&:present?)
            has_go_condition(PREFIX, ONTOLOGY, mpo_id, meo_id, tax_id, bp_id, mf_id, cc_id, select_clause, order_clause, limit, offset)
          elsif tax_id.present?
            has_tax_condition(PREFIX, ONTOLOGY, mpo_id, meo_id, tax_id, select_clause, order_clause, limit, offset)
          elsif meo_id.present?
            has_meo_condition(PREFIX, ONTOLOGY, mpo_id, meo_id, select_clause, order_clause, limit, offset)
          elsif mpo_id.present?
            has_mpo_condition(PREFIX, ONTOLOGY, mpo_id, select_clause, order_clause, limit, offset)
          else
            init_condition(PREFIX, ONTOLOGY, select_clause, order_clause, limit, offset)
          end
        end

        extend ERB::DefMethod

        def_erb_method("init_condition(prefix, ontology, select_clause, order_clause, limit, offset)", 'app/views/sparql_templates/organisms/init_condition.rq.erb')
        def_erb_method("has_mpo_condition(prefix, ontology, mpo_id, select_clause, order_clause, limit, offset)", 'app/views/sparql_templates/organisms/has_mpo_condition.rq.erb')
        def_erb_method("has_meo_condition(prefix, ontology, mpo_id, meo_id, select_clause, order_clause, limit, offset)", 'app/views/sparql_templates/organisms/has_meo_condition.rq.erb')
        def_erb_method("has_tax_condition(prefix, ontology, mpo_id, meo_id, tax_id, select_clause, order_clause, limit, offset)", 'app/views/sparql_templates/organisms/has_tax_condition.rq.erb')
        def_erb_method("has_go_condition(prefix, ontology, mpo_id, meo_id, tax_id, bp_id, mf_id, cc_id, select_clause, order_clause, limit, offset)", 'app/views/sparql_templates/organisms/has_go_condition.rq.erb')

        def_erb_method("find_environments_sparql(prefix, ontology, taxonomies)", 'app/views/sparql_templates/find_environments.rq.erb')
        def_erb_method("find_genome_stats_sparql(prefix, ontology, taxonomies)", 'app/views/sparql_templates/find_genome_stats.rq.erb')
        def_erb_method("find_temperature_sparql(prefix, ontology, taxonomies)", 'app/views/sparql_templates/find_temperature.rq.erb')
        def_erb_method("find_morphology_sparql(prefix, ontology, taxonomies)", 'app/views/sparql_templates/find_morphology.rq.erb')
        def_erb_method("find_energy_source_sparql(prefix, ontology, taxonomies)", 'app/views/sparql_templates/find_energy_source.rq.erb')
      end
    end
  end
end
