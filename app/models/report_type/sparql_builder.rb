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

      def count_sparql(report_type, meo_id, tax_id, bp_id, mf_id, cc_id, mpo_id)
        condition = build_condition(meo_id, tax_id, bp_id, mf_id, cc_id, mpo_id)

        case report_type
        when 'Gene'       then gene_sparql(condition)
        when 'Organism'   then organism_sparql(condition)
        when 'Environment'then environment_sparql(condition)
        end
      end

      def search_sparql(report_type, meo_id, tax_id, bp_id, mf_id, cc_id, mpo_id, limit, offset)
        condition = build_condition(meo_id, tax_id, bp_id, mf_id, cc_id, mpo_id)

        case report_type
        when 'Gene'        then gene_sparql(condition, count: false, limit: limit, offset: offset)
        when 'Organism'    then organism_sparql(condition, count: false, limit: limit, offset: offset)
        when 'Environment' then environment_sparql(condition, count: false, limit: limit, offset: offset)
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

      def build_condition(meo_id, tax_id, bp_id, mf_id, cc_id, mpo_id)
        if (bp_id.present? || mf_id.present? || cc_id.present?)
          ERB.new(File.read('app/views/sparql_templates/has_go_condition.rq.erb')).result(binding)
        elsif tax_id.present?
          ERB.new(File.read('app/views/sparql_templates/has_tax_condition.rq.erb')).result(binding)
        elsif meo_id.present?
          ERB.new(File.read('app/views/sparql_templates/has_meo_condition.rq.erb')).result(binding)
        elsif mpo_id.present?
          ERB.new(File.read('app/views/sparql_templates/has_mpo_condition.rq.erb')).result(binding)
        else
          ERB.new(File.read('app/views/sparql_templates/init_condition.rq.erb')).result(binding)
        end
      end

      def gene_sparql(condition, count: true, limit: 1, offset: 0)
        select_clause = if count
                          "SELECT COUNT(DISTINCT ?uniprot_id) AS ?hits_count"
                        else
                          "SELECT DISTINCT ?uniprot_id ?uniprot_up ?recommended_name ?taxonomy_id ?taxonomy_name"
                        end

        <<-SPARQL.strip_heredoc
          DEFINE sql:select-option "order"
          #{@@prefix[:mccv]}
          #{@@prefix[:meo]}
          #{@@prefix[:mpo]}
          #{@@prefix[:up]}

          #{select_clause}
          WHERE {
            #{condition}
          } LIMIT #{limit} OFFSET #{offset}
        SPARQL
      end

      def organism_sparql(condition, count: true, limit: 1, offset: 0)
        select_clause = if count
                          "SELECT COUNT(DISTINCT ?taxonomy_id) AS ?hits_count"
                        else
                          "SELECT DISTINCT ?taxonomy_id ?taxonomy_name"
                        end

        <<-SPARQL.strip_heredoc
          DEFINE sql:select-option "order"
          #{@@prefix[:mccv]}
          #{@@prefix[:meo]}
          #{@@prefix[:mpo]}
          #{@@prefix[:up]}

          #{select_clause}
          WHERE {
            #{condition}
          } LIMIT #{limit} OFFSET #{offset}
        SPARQL
      end

      def environment_sparql(condition, count: true, limit: 1, offset: 0)
        select_clause = if count
                          "SELECT COUNT(DISTINCT ?meo_id) AS ?hits_count"
                        else
                          "SELECT DISTINCT ?meo_id ?meo_name"
                        end

        <<-SPARQL.strip_heredoc
          DEFINE sql:select-option "order"
          #{@@prefix[:mccv]}
          #{@@prefix[:meo]}
          #{@@prefix[:mpo]}
          #{@@prefix[:up]}

          #{select_clause}
          WHERE {
            {
              SELECT DISTINCT ?taxonomy_id
              WHERE {
                #{condition}
              }
            }

            VALUES ?p_meo { meo:MEO_0000437 meo:MEO_0000440 } .
            GRAPH #{@@ontology[:gold]} {
              ?gold_iri ?p_meo ?meo_iri .
              ?gold_iri mccv:MCCV_000020 ?taxonomy_id .
              BIND (REPLACE(STR(?meo_iri),"http://purl.jp/bio/11/meo/", "" ) AS ?meo_id)
            }

            GRAPH #{@@ontology[:meo]} { ?meo_iri rdfs:label ?meo_name FILTER(LANG(?meo_name) = "" || LANGMATCHES(LANG(?meo_name), "en")) }
          } LIMIT #{limit} OFFSET #{offset}
        SPARQL
      end
    end
  end
end
