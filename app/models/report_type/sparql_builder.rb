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
        goup:            '<http://togogenome.org/graph/group/>',
        refseq:          '<http://togogenome.org/graph/refseq/>',
        stats:           '<http://togogenome.org/graph/stats/>'
      }

      @@prefix = {
        up:     'PREFIX up: <http://purl.uniprot.org/core/>',
        mccv:   'PREFIX mccv: <http://purl.jp/bio/01/mccv#>',
        meo:    'PREFIX meo: <http://purl.jp/bio/11/meo/>',
        mpo:    'PREFIX mpo: <http://purl.jp/bio/01/mpo#>',
        insdc:  'PREFIX insdc: <http://ddbj.nig.ac.jp/ontologies/sequence#>',
        tgstat: 'PREFIX tgstat:<http://togogenome.org/stats/>'
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

      def find_proteins_sparql(genes)
        ERB.new(File.read('app/views/sparql_templates/find_proteins.rq.erb')).result(binding)
      end

      def find_gene_ontologies_sparql(genes)
        ERB.new(File.read('app/views/sparql_templates/find_gene_ontologies.rq.erb')).result(binding)
      end

      def find_environments_sparql(taxonomies)
        ERB.new(File.read('app/views/sparql_templates/find_environments.rq.erb')).result(binding)
      end

      def find_phenotypes_sparql(taxonomies)
        ERB.new(File.read('app/views/sparql_templates/find_phenotypes.rq.erb')).result(binding)
      end

      def find_refseqs_sparql(taxonomies)
        ERB.new(File.read('app/views/sparql_templates/find_refseqs.rq.erb')).result(binding)
      end

      def find_genome_stats_sparql(taxonomies)
        ERB.new(File.read('app/views/sparql_templates/find_genome_stats.rq.erb')).result(binding)
      end

      def find_environment_root_sparql(meos)
        ERB.new(File.read('app/views/sparql_templates/find_environment_root.rq.erb')).result(binding)
      end

      private

      def gene_sparql(meo_id, tax_id, bp_id, mf_id, cc_id, mpo_id, select_clause_type, limit, offset)
        select_clause = if select_clause_type == 'count'
                          "SELECT COUNT(DISTINCT ?togogenome) AS ?hits_count"
                        else
                          "SELECT DISTINCT ?togogenome ?taxonomy_id ?taxonomy_name"
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
        order_clause = (select_clause_type == 'search') ? 'ORDER BY ?taxonomy_name' : ''

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
