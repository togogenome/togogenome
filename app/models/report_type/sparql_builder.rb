module ReportType
  module SparqlBuilder
    extend ActiveSupport::Concern

    module ClassMethods
      def count_sparql(report_type, meo_id, tax_id, bp_id, mf_id, cc_id, mpo_id)
        condition = build_condition(meo_id, tax_id, bp_id, mf_id, cc_id, mpo_id)

        case report_type
        when 'Protein', 'Gene' then protein_count_base(condition)
        when 'Organism'        then organism_count_base(condition)
        when 'Environment'     then environment_count_base(condition)
        end
      end

      def search_sparql(report_type, meo_id, tax_id, bp_id, mf_id, cc_id, mpo_id, limit, offset)
        condition = build_condition(meo_id, tax_id, bp_id, mf_id, cc_id, mpo_id)

        case report_type
        when 'Protein', 'Gene' then protein_search_base(condition, limit, offset)
        when 'Organism'        then organism_search_base(condition, limit, offset)
        when 'Environment'     then environment_search_base(condition, limit, offset)
        end
      end

      def find_genes_sparql(upids)
        common_frame(<<-SPARQL.strip_heredoc)
          SELECT ?uniprot_id ?togogenome
          FROM #{ontology(:tgup)}
          WHERE {
            VALUES ?uniprot_id { #{upids} }
            ?togogenome rdfs:seeAlso ?uniprot_id .
          }
        SPARQL
      end

      def find_gene_ontologies_sparql(uniprots)
        common_frame(<<-SPARQL.strip_heredoc, up: true)
          SELECT ?uniprot_up ?quick_go_uri ?go_name
          FROM #{ontology(:uniprot)}
          FROM #{ontology(:go)}
          WHERE {
            VALUES ?uniprot_up { #{uniprots} }
            ?uniprot_up up:classifiedWith ?up_go_uri FILTER (STRSTARTS(STR(?up_go_uri), "http://purl.uniprot.org/go/")) .
            ?up_go_uri a up:Concept .
            BIND(IRI(REPLACE(STR(?up_go_uri),"http://purl.uniprot.org/go/","http://purl.obolibrary.org/obo/GO_", '')) AS ?obo_go_uri) .
            BIND(IRI(REPLACE(STR(?up_go_uri),"http://purl.uniprot.org/go/","http://www.ebi.ac.uk/QuickGO/GTerm?id=GO:", '')) AS ?quick_go_uri) .
            ?obo_go_uri rdfs:label ?go_name .
            FILTER(LANG(?go_name) = "" || LANGMATCHES(LANG(?go_name), "en")) .
          }
        SPARQL
      end

      def find_environments_sparql(taxonomies)
        common_frame(<<-SPARQL.strip_heredoc, mccv: true, meo: true)
          SELECT DISTINCT ?meo_id ?taxonomy_id ?meo_name
          FROM #{ontology(:gold)}
          FROM #{ontology(:mpo)}
          FROM #{ontology(:meo)}
          WHERE {
            VALUES ?taxonomy_id { #{taxonomies} }
            VALUES ?p_meo { meo:MEO_0000437 meo:MEO_0000440 }
            ?gold_iri ?p_meo ?meo_iri .
            ?gold_iri mccv:MCCV_000020 ?taxonomy_id .
            BIND (REPLACE(STR(?meo_iri),"http://purl.jp/bio/11/meo/", "" ) AS ?meo_id)

            ?meo_iri rdfs:label ?meo_name FILTER(LANG(?meo_name) = "" || LANGMATCHES(LANG(?meo_name), "en")) .
          }
        SPARQL
      end

      def find_phenotypes_sparql(taxonomies)
        common_frame(<<-SPARQL.strip_heredoc)
          SELECT ?taxonomy_id ?mpo_id ?mpo_name
          FROM #{ontology(:gold)}
          FROM #{ontology(:mpo)}
          WHERE {
            VALUES ?taxonomy_id { #{taxonomies} }
            FILTER (STRSTARTS(STR(?mpo_url), "http://purl.jp/bio/01/mpo#MPO_"))
            ?taxonomy_id ?p ?mpo_url .
            BIND (REPLACE(STR(?mpo_url),"http://purl.jp/bio/01/mpo#", "" ) AS ?mpo_id)
            ?mpo_url rdfs:label ?mpo_name .
            FILTER(LANG(?mpo_name) = "" || LANGMATCHES(LANG(?mpo_name), "en")) .
          }
        SPARQL
      end

      private

      def common_frame(select_query, mccv: false, meo: false, mpo: false, up: false)
        prefixes = []
        prefixes << 'PREFIX mccv: <http://purl.jp/bio/01/mccv#>' if mccv
        prefixes << 'PREFIX meo: <http://purl.jp/bio/11/meo/>'   if meo
        prefixes << 'PREFIX mpo: <http://purl.jp/bio/01/mpo#>'   if mpo
        prefixes << 'PREFIX up: <http://purl.uniprot.org/core/>' if up

        <<-SPARQL.strip_heredoc
          DEFINE sql:select-option "order"
          #{prefixes.join("\n")}
            #{select_query}
        SPARQL
      end

      def ontology(key)
        case key
        when :uniprot         then '<http://togogenome.org/graph/uniprot/>'
        when :taxonomy        then '<http://togogenome.org/graph/taxonomy/>'
        when :go              then '<http://togogenome.org/graph/go/>'
        when :mpo             then '<http://togogenome.org/graph/mpo/>'
        when :meo             then '<http://togogenome.org/graph/meo/>'
        when :gold            then '<http://togogenome.org/graph/gold/>'
        when :tgup            then '<http://togogenome.org/graph/tgup/>'
        when :tgtax           then '<http://togogenome.org/graph/tgtax/>'
        when :meo_descendants then '<http://togogenome.org/graph/meo_descendants/>'
        when :mpo_descendants then '<http://togogenome.org/graph/mpo_descendants/>'
        when :goup            then '<http://togogenome.org/graph/group/>'
        end
      end

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

      def protein_count_base(condition)
        common_frame(<<-SPARQL.strip_heredoc, mccv: true, meo: true, mpo: true, up: true)
          SELECT COUNT(DISTINCT ?uniprot_id) AS ?hits_count
          WHERE {
            #{condition}
          }
        SPARQL
      end

      # protein_count_base と同じ処理が多いのでなんとかする
      def organism_count_base(condition)
        common_frame(<<-SPARQL.strip_heredoc, mccv: true, meo: true, mpo: true, up: true)
          SELECT COUNT(DISTINCT ?taxonomy_id) AS ?hits_count
          WHERE {
            #{condition}
          }
        SPARQL
      end

      def environment_count_base(condition)
        common_frame(<<-SPARQL.strip_heredoc, mccv: true, meo: true, mpo: true, up: true)
          SELECT COUNT(DISTINCT ?meo_id) AS ?hits_count
          WHERE {
            {
              SELECT DISTINCT ?taxonomy_id
              WHERE {
                #{condition}
              }
            }

            VALUES ?p_meo { meo:MEO_0000437 meo:MEO_0000440 } .
            GRAPH #{ontology(:gold)} {
              ?gold_iri ?p_meo ?meo_iri .
              ?gold_iri mccv:MCCV_000020 ?taxonomy_id .
              BIND (REPLACE(STR(?meo_iri),"http://purl.jp/bio/11/meo/", "" ) AS ?meo_id)
            }

            GRAPH #{ontology(:meo)} { ?meo_iri rdfs:label ?meo_name FILTER(LANG(?meo_name) = "" || LANGMATCHES(LANG(?meo_name), "en")) }
          }
        SPARQL
      end

      def protein_search_base(condition, limit, offset)
        common_frame(<<-SPARQL.strip_heredoc, mccv: true, meo: true, mpo: true, up: true)
          SELECT DISTINCT ?uniprot_id ?uniprot_up ?recommended_name ?taxonomy_id ?taxonomy_name
          WHERE {
            #{condition}
          } LIMIT #{limit} OFFSET #{offset}
        SPARQL
      end

      # protein_search_base と同じ処理が多いのでなんとかする
      def organism_search_base(condition, limit, offset)
        common_frame(<<-SPARQL.strip_heredoc, mccv: true, meo: true, mpo: true, up: true)
          SELECT DISTINCT ?taxonomy_id ?taxonomy_name
          WHERE {
            #{condition}
          } LIMIT #{limit} OFFSET #{offset}
        SPARQL
      end

      def environment_search_base(condition, limit, offset)
        common_frame(<<-SPARQL.strip_heredoc, mccv: true, meo: true, mpo: true, up: true)
          SELECT DISTINCT ?meo_id ?meo_name
          WHERE {
            {
              SELECT DISTINCT ?taxonomy_id
              WHERE {
                #{condition}
              }
            }

            VALUES ?p_meo { meo:MEO_0000437 meo:MEO_0000440 } .
            GRAPH #{ontology(:gold)} {
              ?gold_iri ?p_meo ?meo_iri .
              ?gold_iri mccv:MCCV_000020 ?taxonomy_id .
              BIND (REPLACE(STR(?meo_iri),"http://purl.jp/bio/11/meo/", "" ) AS ?meo_id)
            }

            GRAPH #{ontology(:meo)} { ?meo_iri rdfs:label ?meo_name FILTER(LANG(?meo_name) = "" || LANGMATCHES(LANG(?meo_name), "en")) }
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
        "GRAPH #{ontology(:taxonomy)} { ?taxonomy_id rdfs:label ?taxonomy_name }"
      end

      def up_to_upname
        "GRAPH #{ontology(:uniprot)} { ?uniprot_up up:recommendedName/up:fullName ?recommended_name }"
      end

      def taxid_to_togogenome_to_upid
        <<-SPARQL
          GRAPH #{ontology(:tgup)} {
            ?togogenome rdfs:seeAlso ?taxonomy_id .
            ?togogenome rdfs:seeAlso ?uniprot_id .
            ?uniprot_id rdfs:seeAlso ?uniprot_up .
          }
        SPARQL
      end

      def upid_to_togogenome_to_taxid
        <<-SPARQL
          GRAPH #{ontology(:tgup)} {
            ?togogenome rdfs:seeAlso ?uniprot_id .
            ?togogenome rdfs:seeAlso ?taxonomy_id .
            ?uniprot_id rdfs:seeAlso ?uniprot_up .
          }
        SPARQL
      end

      def tax_hierarchy(tax_id)
        return '' if tax_id.empty?

        "GRAPH #{ontology(:tgtax)} { ?taxonomy_id rdfs:subClassOf <#{tax_id}> }"
      end

      def meoid_to_taxid(meo_id, upper_side = false)
        return '' if meo_id.empty?

        if upper_side
          <<-SPARQL
            VALUES ?gold_meo { meo:MEO_0000437 meo:MEO_0000440 }
            GRAPH #{ontology(:meo_descendants)} { ?meo_id rdfs:subClassOf <#{meo_id}> }
            GRAPH #{ontology(:gold)} {
              ?gold_id mccv:MCCV_000020 ?taxonomy_id .
              ?gold_id ?gold_meo ?meo_id .
            }
          SPARQL
        else
          <<-SPARQL
            VALUES ?gold_meo { meo:MEO_0000437 meo:MEO_0000440 }
            GRAPH #{ontology(:gold)} {
              ?gold_id mccv:MCCV_000020 ?taxonomy_id .
              ?gold_id ?gold_meo ?meo_id .
            }
            GRAPH #{ontology(:meo_descendants)} { ?meo_id rdfs:subClassOf <#{meo_id}> }
          SPARQL
        end
      end

      def mpoid_to_taxid(mpo_id, upper_side = false)
        return '' if mpo_id.empty?

        if upper_side
          <<-SPARQL
            GRAPH #{ontology(:mpo_descendants)} { ?mpo_id rdfs:subClassOf <#{mpo_id}> }
            GRAPH #{ontology(:gold)} { ?taxonomy_id ?tax_mpo ?mpo_id FILTER (?tax_mpo IN (mpo:MPO_10002, mpo:MPO_10001, mpo:MPO_10003, mpo:MPO_10005, mpo:MPO_10009, mpo:MPO_10010, mpo:MPO_10011, mpo:MPO_10013, mpo:MPO_10014, mpo:MPO_10015, mpo:MPO_10016, mpo:MPO_10006, mpo:MPO_10007)) }
          SPARQL
        else
          <<-SPARQL
            GRAPH #{ontology(:gold)} { ?taxonomy_id ?tax_mpo ?mpo_id FILTER (?tax_mpo IN (mpo:MPO_10002, mpo:MPO_10001, mpo:MPO_10003, mpo:MPO_10005, mpo:MPO_10009, mpo:MPO_10010, mpo:MPO_10011, mpo:MPO_10013, mpo:MPO_10014, mpo:MPO_10015, mpo:MPO_10016, mpo:MPO_10006, mpo:MPO_10007)) }
            GRAPH #{ontology(:mpo_descendants)} { ?mpo_id rdfs:subClassOf <#{mpo_id}> }
          SPARQL
        end
      end

      def goid_to_upid(bp_id, mf_id, cc_id)
        <<-SPARQL
          GRAPH #{ontology(:goup)} {
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
