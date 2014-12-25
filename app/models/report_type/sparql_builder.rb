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
          has_go_condition(meo_id, tax_id, bp_id, mf_id, cc_id, mpo_id)
        elsif tax_id.present?
          has_tax_condition(meo_id, tax_id, mpo_id)
        elsif meo_id.present?
          has_meo_condition(meo_id, mpo_id)
        elsif mpo_id.present?
          has_mpo_condition(mpo_id)
        else
          init_condition
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

      def has_go_condition(meo_id, tax_id, bp_id, mf_id, cc_id, mpo_id)
        <<-SPARQL
          #{goid_to_upid(bp_id, mf_id, cc_id)}
          #{upid_to_togogenome_to_taxid}
          #{up_to_upname}
          #{taxid_to_taxname}
          #{tax_hierarchy(tax_id)}
          #{meoid_to_taxid(meo_id)}
          #{mpoid_to_taxid(mpo_id)}
        SPARQL
      end

      def has_tax_condition(meo_id, tax_id, mpo_id)
        <<-SPARQL
          #{tax_hierarchy(tax_id)}
          #{taxid_to_taxname}
          #{taxid_to_togogenome_to_upid}
          #{up_to_upname}
          #{meoid_to_taxid(meo_id)}
          #{mpoid_to_taxid(mpo_id)}
        SPARQL
      end

      def has_meo_condition(meo_id, mpo_id)
        <<-SPARQL
          #{meoid_to_taxid(meo_id, true)}
          #{mpoid_to_taxid(mpo_id)}
          #{taxid_to_taxname}
          #{taxid_to_togogenome_to_upid}
          #{up_to_upname}
        SPARQL
      end

      def has_mpo_condition(mpo_id)
        <<-SPARQL
          #{mpoid_to_taxid(mpo_id, true)}
          #{taxid_to_taxname}
          #{taxid_to_togogenome_to_upid}
          #{up_to_upname}
        SPARQL
      end

      def init_condition
        <<-SPARQL
          #{tax_hierarchy('http://identifiers.org/taxonomy/1')}
          #{taxid_to_taxname}
          #{taxid_to_togogenome_to_upid}
          #{up_to_upname}
        SPARQL
      end

      def taxid_to_taxname
        "GRAPH #{@@ontology[:taxonomy]} { ?taxonomy_id rdfs:label ?taxonomy_name }"
      end

      def up_to_upname
        "GRAPH #{@@ontology[:uniprot]} { ?uniprot_up up:recommendedName/up:fullName ?recommended_name }"
      end

      def taxid_to_togogenome_to_upid
        <<-SPARQL
          GRAPH #{@@ontology[:tgup]} {
            ?togogenome rdfs:seeAlso ?taxonomy_id .
            ?togogenome rdfs:seeAlso ?uniprot_id .
            ?uniprot_id rdfs:seeAlso ?uniprot_up .
          }
        SPARQL
      end

      def upid_to_togogenome_to_taxid
        <<-SPARQL
          GRAPH #{@@ontology[:tgup]} {
            ?togogenome rdfs:seeAlso ?uniprot_id .
            ?togogenome rdfs:seeAlso ?taxonomy_id .
            ?uniprot_id rdfs:seeAlso ?uniprot_up .
          }
        SPARQL
      end

      def tax_hierarchy(tax_id)
        return '' if tax_id.empty?

        "GRAPH #{@@ontology[:tgtax]} { ?taxonomy_id rdfs:subClassOf <#{tax_id}> }"
      end

      def meoid_to_taxid(meo_id, upper_side = false)
        return '' if meo_id.empty?

        if upper_side
          <<-SPARQL
            VALUES ?gold_meo { meo:MEO_0000437 meo:MEO_0000440 }
            GRAPH #{@@ontology[:meo_descendants]} { ?meo_id rdfs:subClassOf <#{meo_id}> }
            GRAPH #{@@ontology[:gold]} {
              ?gold_id mccv:MCCV_000020 ?taxonomy_id .
              ?gold_id ?gold_meo ?meo_id .
            }
          SPARQL
        else
          <<-SPARQL
            VALUES ?gold_meo { meo:MEO_0000437 meo:MEO_0000440 }
            GRAPH #{@@ontology[:gold]} {
              ?gold_id mccv:MCCV_000020 ?taxonomy_id .
              ?gold_id ?gold_meo ?meo_id .
            }
            GRAPH #{@@ontology[:meo_descendants]} { ?meo_id rdfs:subClassOf <#{meo_id}> }
          SPARQL
        end
      end

      def mpoid_to_taxid(mpo_id, upper_side = false)
        return '' if mpo_id.empty?

        if upper_side
          <<-SPARQL
            GRAPH #{@@ontology[:mpo_descendants]} { ?mpo_id rdfs:subClassOf <#{mpo_id}> }
            GRAPH #{@@ontology[:gold]} { ?taxonomy_id ?tax_mpo ?mpo_id FILTER (?tax_mpo IN (mpo:MPO_10002, mpo:MPO_10001, mpo:MPO_10003, mpo:MPO_10005, mpo:MPO_10009, mpo:MPO_10010, mpo:MPO_10011, mpo:MPO_10013, mpo:MPO_10014, mpo:MPO_10015, mpo:MPO_10016, mpo:MPO_10006, mpo:MPO_10007)) }
          SPARQL
        else
          <<-SPARQL
            GRAPH #{@@ontology[:gold]} { ?taxonomy_id ?tax_mpo ?mpo_id FILTER (?tax_mpo IN (mpo:MPO_10002, mpo:MPO_10001, mpo:MPO_10003, mpo:MPO_10005, mpo:MPO_10009, mpo:MPO_10010, mpo:MPO_10011, mpo:MPO_10013, mpo:MPO_10014, mpo:MPO_10015, mpo:MPO_10016, mpo:MPO_10006, mpo:MPO_10007)) }
            GRAPH #{@@ontology[:mpo_descendants]} { ?mpo_id rdfs:subClassOf <#{mpo_id}> }
          SPARQL
        end
      end

      def goid_to_upid(bp_id, mf_id, cc_id)
        <<-SPARQL
          GRAPH #{@@ontology[:goup]} {
            #{go_upid(bp_id)}
            #{go_upid(mf_id)}
            #{go_upid(cc_id)}
          }
        SPARQL
      end

      def go_upid(go_id)
        return '' if go_id.empty?

        go_up = "http://purl.uniprot.org/go/#{go_id.split('/GO_').last}"
        "<#{go_up}> up:classifiedWith ?uniprot_id ."
      end
    end
  end
end
