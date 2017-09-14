require 'sparql_util'

module Sequence
  class Genome
    include Queryable

    class << self
      def search(sequence)
        genomes = Sequence::GggenomeSearch.search(sequence)

        sparqls = build_sparqls(genomes)
        results = sparqls.flat_map {|sparql| query(sparql) }

        gene_results = [:previous, :overlap, :next].map do |pos|
          [ pos, build_gene_sparqls(genomes, pos).flat_map { |s| query(s) } ]
        end.to_h

        genomes.map do |genome|
          refseq = results.select {|r| r[:refseq] == genome.refseq }
          so = refseq.map { |r| { uri: r[:sequence_ontology], name: r[:sequence_ontology_name] } }

          attributes = { sequence_ontologies: so,
                         locus_tags: refseq.map {|r| r[:locus_tag] }.compact.uniq,
                         products: refseq.map {|r| r[:product] }.compact.uniq }

          genes = gene_results.map do |pos, val|
            match = val.select do |v|
              v[:refseq_id] == genome.refseq &&
                  v[:begin].to_i == genome.position &&
                  v[:end].to_i == genome.position_end
            end
            [pos, match.map { |v| { gene_name: v[:gene_name], togogenome: v[:togogenome] } }]
          end.to_h

          genome.to_h.merge(attributes).merge(genes)
         end
      end

      def build_sparqls(gggenome)
        # slice の理由
        # gggenome での検索結果が多い時、それらをまとめて1つのSPARQL にすると、
        # SPARQLのサーバで 'error code 414: uri too large' にひっかかってしまうため Query を分割している
        gggenome.each_slice(300).map do |sub_results|
          <<-SPARQL.strip_heredoc
            DEFINE sql:select-option "order"
            #{prefixes}

            SELECT DISTINCT ?refseq ?name ?sequence_ontology ?sequence_ontology_name ?locus_tag ?product
            FROM #{SPARQLUtil::ONTOLOGY[:so]}
            FROM #{SPARQLUtil::ONTOLOGY[:refseq]}
            WHERE {
              {
                SELECT DISTINCT ?refseq ?name ?sequence_ontology ?sequence_ontology_name ?feature
                WHERE {
                  VALUES (?refseq_uri ?position ?position_end ?name ?strand ) {
                    #{bind_values(sub_results)}
                  }
                  ?refseq_uri insdc:sequence_version ?refseq .
                  ?refseq_uri insdc:sequence ?sequence .

                  ?feature obo:so_part_of+ ?sequence .
                  ?feature faldo:location ?loc .
                  ?loc faldo:begin/faldo:position ?feature_position_beg .
                  ?loc faldo:end/faldo:position ?feature_position_end .
                  ?feature rdfs:subClassOf ?sequence_ontology .
                  ?sequence_ontology rdfs:label ?sequence_ontology_name .

                  BIND ( IF (?strand = "+", ?feature_position_beg, ?feature_position_end) AS ?begin ).
                  BIND ( IF (?strand = "+", ?feature_position_end, ?feature_position_beg) AS ?end ).
                  FILTER(?begin < ?position && ?position < ?end && ?begin != 1)
                }
              }
              OPTIONAL { ?feature insdc:locus_tag ?locus_tag . }
              OPTIONAL { ?feature insdc:product ?product .}
            }
          SPARQL
        end
      end

      def build_gene_sparqls(gggenome, pos)
        gggenome.each_slice(300).map do |sub_results|
          <<-SPARQL.strip_heredoc
            DEFINE sql:select-option "order"
            #{prefixes}
            
            SELECT #{make_select_target}
            #{make_from_clause}
            WHERE {
              #{make_where_clause(sub_results, pos)}
            }
          SPARQL
        end
      end

      private

      def prefixes
        %i[insdc faldo obo refseq].map { |x| SPARQLUtil::PREFIX[x] }.join("\n")
      end

      def make_select_target
        '?refseq_id ?begin ?end ?togogenome ?gene_name'
      end

      def make_from_clause
        ["FROM #{SPARQLUtil::ONTOLOGY[:tgup]}", "FROM #{SPARQLUtil::ONTOLOGY[:refseq]}"].join("\n")
      end

      def make_where_clause(sub_results, pos)
        case pos
        when :overlap
          <<-EOS
            VALUES (?refseq_uri ?begin ?end ?dummy1 ?dummy2) {
              #{bind_values(sub_results)}
            }
            #{make_common_triple_pettern}
            FILTER (
              ?faldo_begin != 1 &&
              ! ( ( ?faldo_begin < ?begin && ?faldo_end < ?begin ) ||
                ( ?end < ?faldo_begin && ?end < ?faldo_end ) ) ||
                ( ?faldo_begin < ?begin && ?end < ?faldo_end ) )
          EOS
        when :previous
          <<-EOS
            #{make_sub_query(sub_results, pos)}
            #{make_common_triple_pettern}
            FILTER ( ?faldo_begin = ?max_pos || ?faldo_end = ?max_pos )
          EOS
        when :next
          <<-EOS
            #{make_sub_query(sub_results, pos)}
            #{make_common_triple_pettern}
            FILTER ( ?faldo_begin = ?min_pos || ?faldo_end = ?min_pos )
          EOS
        else
          raise("unknown position: #{pos}")
        end
      end

      def make_common_triple_pettern(sub_query = false)
        [refseq(sub_query),
         feature(sub_query),
         location(sub_query),
         togogenome(sub_query)].join("\n")
      end

      def refseq(sub_query = false)
        str = '?refseq_uri insdc:sequence ?seq '
        str << if sub_query
                 '.'
               else
                 ";\n insdc:sequence_version ?refseq_id ."
               end
      end

      def feature(sub_query = false)
        <<-EOS
          ?feature obo:so_part_of ?seq ;
            rdfs:label ?gene_name ;
            faldo:location ?loc .
        EOS
      end

      def location(sub_query = false)
        <<-EOS
          ?loc faldo:begin/faldo:position ?faldo_begin ;
            faldo:end/faldo:position ?faldo_end .
        EOS
      end

      def togogenome(sub_query = false)
        '?togogenome skos:exactMatch ?feature .'
      end

      def make_sub_query(sub_results, pos)
        case pos
        when :previous
          <<-EOS
            {
              SELECT ?refseq_uri ?begin ?end (MAX(?faldo_end) AS ?max_pos)
              #{make_from_clause}
              WHERE {
                VALUES (?refseq_uri ?begin ?end ?dummy1 ?dummy2) {
                  #{bind_values(sub_results)}
                }
                #{make_common_triple_pettern(true)}
                FILTER( ?faldo_begin != 1 && (?faldo_begin < ?begin && ?faldo_end < ?begin) )
              } GROUP BY ?refseq_uri ?begin ?end
            }
          EOS
        when :next
          <<-EOS
            {
              SELECT ?refseq_uri ?begin ?end (MIN(?faldo_begin) AS ?min_pos)
              #{make_from_clause}
              WHERE {
                VALUES (?refseq_uri ?begin ?end ?dummy1 ?dummy2) {
                  #{bind_values(sub_results)}
                }
                #{make_common_triple_pettern(true)}
                FILTER( ?faldo_begin != 1 && (?end < ?faldo_begin &&  ?end < ?faldo_end) )
              } GROUP BY ?refseq_uri ?begin ?end
            }
          EOS
        else
          raise("unknown position: #{pos}")
        end
      end

      def bind_values(genomes)
        genomes.map { |genome|
          "( refseq:#{genome.refseq} #{genome.position} #{genome.position_end} \"#{genome.name}\" \"#{genome.strand}\" )"
        }.join("\n")
      end
    end
  end
end
