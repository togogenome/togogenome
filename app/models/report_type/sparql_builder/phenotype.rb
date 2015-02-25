require 'erb'
require 'sparql_util'

module ReportType
  module SparqlBuilder
    module Phenotype
      extend ActiveSupport::Concern

      module ClassMethods
        include SPARQLUtil

        def build_base_sparql(meo_id, tax_id, bp_id, mf_id, cc_id, mpo_id, select_clause, order_clause = '', limit = 1, offset = 0)
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
        def_erb_method("init_condition(prefix, ontology, select_clause, order_clause, limit, offset)", 'app/views/sparql_templates/phenotypes/init_condition.rq.erb')
        def_erb_method("has_mpo_condition(prefix, ontology, mpo_id, select_clause, order_clause, limit, offset)", 'app/views/sparql_templates/phenotypes/has_mpo_condition.rq.erb')
        def_erb_method("has_meo_condition(prefix, ontology, mpo_id, meo_id, select_clause, order_clause, limit, offset)", 'app/views/sparql_templates/phenotypes/has_meo_condition.rq.erb')
        def_erb_method("has_tax_condition(prefix, ontology, mpo_id, meo_id, tax_id, select_clause, order_clause, limit, offset)", 'app/views/sparql_templates/phenotypes/has_tax_condition.rq.erb')
        def_erb_method("has_go_condition(prefix, ontology, mpo_id, meo_id, tax_id, bp_id, mf_id, cc_id, select_clause, order_clause, limit, offset)", 'app/views/sparql_templates/phenotypes/has_go_condition.rq.erb')

        def_erb_method("find_inhabitants_sparql(prefix, ontology, mpos)", 'app/views/sparql_templates/find_phenotype_inhabitants.rq.erb')
      end
    end
  end
end
