require 'erb'

module ReportType
  module SparqlBuilder
    extend ActiveSupport::Concern

    module ClassMethods
      @@ontology = {
        uniprot:         '<http://togogenome.org/graph/uniprot/>',
        taxonomy:        '<http://togogenome.org/graph/taxonomy/>',
        go:              '<http://togogenome.org/graph/go/>',
        mpo:             '<http://togogenome.org/graph/mpo/>',
        meo:             '<http://togogenome.org/graph/meo/>',
        gold:            '<http://togogenome.org/graph/gold/>',
        tgup:            '<http://togogenome.org/graph/tgup/>',
        tgtax:           '<http://togogenome.org/graph/tgtax/>',
        meo_descendants: '<http://togogenome.org/graph/meo_descendants/>',
        mpo_descendants: '<http://togogenome.org/graph/mpo_descendants/>',
        goup:            '<http://togogenome.org/graph/group/>'
      }

      @@prefix = {
        up:   'PREFIX up: <http://purl.uniprot.org/core/>',
        mccv: 'PREFIX mccv: <http://purl.jp/bio/01/mccv#>',
        meo:  'PREFIX meo: <http://purl.jp/bio/11/meo/>',
        mpo:  'PREFIX mpo: <http://purl.jp/bio/01/mpo#>'
      }

      def build_sparql(report_type, select_clause_type, meo_id, tax_id, bp_id, mf_id, cc_id, mpo_id, limit = 1, offset = 0)
        case report_type
        when 'Gene'
          gene_sparql(meo_id, tax_id, bp_id, mf_id, cc_id, mpo_id, select_clause_type, limit, offset)
        when 'Organism'
          organism_sparql(meo_id, tax_id, bp_id, mf_id, cc_id, mpo_id, select_clause_type, limit, offset)
        when 'Environment'
          environment_sparql(meo_id, tax_id, bp_id, mf_id, cc_id, mpo_id, select_clause_type, limit, offset)
        end
      end

      def find_genes_sparql(upids)
        ERB.new(File.read('app/views/sparql_templates/find_genes.rq.erb')).result(binding)
      end

      def find_gene_ontologies_sparql(uniprots)
        ERB.new(File.read('app/views/sparql_templates/find_gene_ontologies.rq.erb')).result(binding)
      end

      def find_environments_sparql(taxonomies)
        ERB.new(File.read('app/views/sparql_templates/find_environments.rq.erb')).result(binding)
      end

      def find_phenotypes_sparql(taxonomies)
        ERB.new(File.read('app/views/sparql_templates/find_phenotypes.rq.erb')).result(binding)
      end

      private

      def gene_sparql(meo_id, tax_id, bp_id, mf_id, cc_id, mpo_id, select_clause_type, limit, offset)
        select_clause = if select_clause_type == 'count'
                          "SELECT COUNT(DISTINCT ?uniprot_id) AS ?hits_count"
                        else
                          "SELECT DISTINCT ?uniprot_id ?uniprot_up ?recommended_name ?taxonomy_id ?taxonomy_name"
                        end

        if (bp_id.present? || mf_id.present? || cc_id.present?)
          ERB.new(File.read('app/views/sparql_templates/genes/has_go_condition.rq.erb')).result(binding)
        elsif tax_id.present?
          ERB.new(File.read('app/views/sparql_templates/genes/has_tax_condition.rq.erb')).result(binding)
        elsif meo_id.present?
          ERB.new(File.read('app/views/sparql_templates/genes/has_meo_condition.rq.erb')).result(binding)
        elsif mpo_id.present?
          ERB.new(File.read('app/views/sparql_templates/genes/has_mpo_condition.rq.erb')).result(binding)
        else
          ERB.new(File.read('app/views/sparql_templates/genes/init_condition.rq.erb')).result(binding)
        end
      end

      def organism_sparql(meo_id, tax_id, bp_id, mf_id, cc_id, mpo_id, select_clause_type, limit, offset)
        select_clause = if select_clause_type == 'count'
                          "SELECT COUNT(DISTINCT ?taxonomy_id) AS ?hits_count"
                        else
                          "SELECT DISTINCT ?taxonomy_id ?taxonomy_name"
                        end

        if (bp_id.present? || mf_id.present? || cc_id.present?)
          ERB.new(File.read('app/views/sparql_templates/organisms/has_go_condition.rq.erb')).result(binding)
        elsif tax_id.present?
          ERB.new(File.read('app/views/sparql_templates/organisms/has_tax_condition.rq.erb')).result(binding)
        elsif meo_id.present?
          ERB.new(File.read('app/views/sparql_templates/organisms/has_meo_condition.rq.erb')).result(binding)
        elsif mpo_id.present?
          ERB.new(File.read('app/views/sparql_templates/organisms/has_mpo_condition.rq.erb')).result(binding)
        else
          ERB.new(File.read('app/views/sparql_templates/organisms/init_condition.rq.erb')).result(binding)
        end
      end

      def environment_sparql(meo_id, tax_id, bp_id, mf_id, cc_id, mpo_id, select_clause_type, limit, offset)
        select_clause = if select_clause_type == 'count'
                          "SELECT COUNT(DISTINCT ?meo_id) AS ?hits_count"
                        else
                          "SELECT DISTINCT ?meo_id ?meo_name"
                        end

        if (bp_id.present? || mf_id.present? || cc_id.present?)
          ERB.new(File.read('app/views/sparql_templates/environments/has_go_condition.rq.erb')).result(binding)
        elsif tax_id.present?
          ERB.new(File.read('app/views/sparql_templates/environments/has_tax_condition.rq.erb')).result(binding)
        elsif meo_id.present?
          ERB.new(File.read('app/views/sparql_templates/environments/has_meo_condition.rq.erb')).result(binding)
        elsif mpo_id.present?
          ERB.new(File.read('app/views/sparql_templates/environments/has_mpo_condition.rq.erb')).result(binding)
        else
          ERB.new(File.read('app/views/sparql_templates/environments/init_condition.rq.erb')).result(binding)
        end
      end
    end
  end
end
