require 'erb'
require 'sparql_util'

module ReportType
  module SparqlBuilder
    module Gene
      extend ActiveSupport::Concern

      module ClassMethods
        include SPARQLUtil

        def build_base_sparql(meo_id, tax_id, bp_id, mf_id, cc_id, mpo_id, select_clause, limit = 1, offset = 0)
          if [bp_id, mf_id, cc_id].any?(&:present?)
            has_go_condition(PREFIX, ONTOLOGY, mpo_id, meo_id, tax_id, bp_id, mf_id, cc_id, select_clause, limit, offset)
          elsif tax_id.present?
            has_tax_condition(PREFIX, ONTOLOGY, mpo_id, meo_id, tax_id, select_clause, limit, offset)
          elsif meo_id.present?
            has_meo_condition(PREFIX, ONTOLOGY, mpo_id, meo_id, select_clause, limit, offset)
          elsif mpo_id.present?
            has_mpo_condition(PREFIX, ONTOLOGY, mpo_id, select_clause, limit, offset)
          else
            init_condition(PREFIX, ONTOLOGY, select_clause, limit, offset)
          end
        end

        extend ERB::DefMethod

        def_erb_method("init_condition(prefix, ontology, select_clause, limit, offset)", 'app/views/sparql_templates/genes/init_condition.rq.erb')
        def_erb_method("has_mpo_condition(prefix, ontology, mpo_id, select_clause, limit, offset)", 'app/views/sparql_templates/genes/has_mpo_condition.rq.erb')
        def_erb_method("has_meo_condition(prefix, ontology, mpo_id, meo_id, select_clause, limit, offset)", 'app/views/sparql_templates/genes/has_meo_condition.rq.erb')
        def_erb_method("has_tax_condition(prefix, ontology, mpo_id, meo_id, tax_id, select_clause, limit, offset)", 'app/views/sparql_templates/genes/has_tax_condition.rq.erb')
        def_erb_method("has_go_condition(prefix, ontology, mpo_id, meo_id, tax_id, bp_id, mf_id, cc_id, select_clause, limit, offset)", 'app/views/sparql_templates/genes/has_go_condition.rq.erb')

        def_erb_method("find_proteins_sparql(prefix, ontology, genes)", 'app/views/sparql_templates/find_proteins.rq.erb')
        def_erb_method("find_gene_ontologies_sparql(prefix, ontology, genes)", 'app/views/sparql_templates/find_gene_ontologies.rq.erb')
      end
    end
  end
end
