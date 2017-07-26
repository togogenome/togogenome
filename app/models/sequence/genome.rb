require 'sparql_util'

module Sequence
  class Genome
    include Queryable

    class << self
      def search(sequence)
        genomes = Sequence::GggenomeSearch.search(sequence)

        sparqls = build_sparqls(genomes)
        results = sparqls.flat_map {|sparql| query(sparql) }

        genomes.map do |genome|
          so = results.select {|r| r[:name] == genome.name }
          genome.to_h.merge(
            sequence_ontologies: so.map {|r| {uri: r[:sequence_ontology], name: r[:sequence_ontology_name]} },
            locus_tags: so.map {|r| r[:locus_tag] }.compact.uniq,
            products: so.map {|r| r[:product] }.compact.uniq
          ).merge(fetch_genes(genome.taxonomy, genome.position, genome.position_end))
        end
      end

      def build_sparqls(gggenome)
        # slice の理由
        # gggenome での検索結果が多い時、それらをまとめて1つのSPARQL にすると、
        # SPARQLのサーバで 'error code 414: uri too large' にひっかかってしまうため Query を分割している
        gggenome.each_slice(300).map do |sub_results|
          <<-SPARQL.strip_heredoc
            DEFINE sql:select-option "order"
            #{SPARQLUtil::PREFIX[:insdc]}
            #{SPARQLUtil::PREFIX[:faldo]}
            #{SPARQLUtil::PREFIX[:obo]}
            SELECT DISTINCT ?name ?sequence_ontology ?sequence_ontology_name ?locus_tag ?product
            FROM #{SPARQLUtil::ONTOLOGY[:so]}
            FROM #{SPARQLUtil::ONTOLOGY[:refseq]}
            WHERE {
              {
                SELECT DISTINCT ?name ?sequence_ontology ?sequence_ontology_name ?feature
                WHERE {
                  VALUES (?name ?position ?position_end ?refseq ?strand ) {
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

      private

      def bind_values(genomes)
        genomes.map {|genome|
          "( \"#{genome.name}\" #{genome.position} #{genome.position_end} \"#{genome.refseq}\" \"#{genome.strand}\" )"
        }.join("\n")
      end

      def fetch_genes(tax_id, result_begin, result_end)
        r_begin, r_end = [result_begin.to_i, result_end.to_i].sort

        genes = query(build_gene_sparql(tax_id, r_begin, r_end))
        prev, other = genes.partition { |g| g[:faldo_begin].to_i < r_begin && g[:faldo_end].to_i < r_begin }
        nxt, overlap = other.partition { |g| r_end < g[:faldo_begin].to_i && r_end < g[:faldo_end].to_i }

        { previous: prev, overlap: overlap, next: nxt }
      end

      def build_gene_sparql(tax_id, result_begin, result_end)
        <<-SPARQL.strip_heredoc
          #{SPARQLUtil::PREFIX[:insdc]}
          #{SPARQLUtil::PREFIX[:faldo]}
          #{SPARQLUtil::PREFIX[:obo]}
          SELECT ?togogenome ?gene_name ?faldo_begin ?faldo_end
          FROM <http://togogenome.org/graph/tgup>
          FROM <http://togogenome.org/graph/refseq>
          WHERE {
            VALUES (?taxonomy_id ?begin ?end) {
              ( \"#{tax_id.to_s}\" #{result_begin.to_s} #{result_end.to_s} )
            }
            ?togogenome rdfs:seeAlso ?taxonomy ;
                        skos:exactMatch ?feature .
            ?taxonomy a insdc:Taxonomy ;
                      rdfs:label ?taxonomy_id .
            ?feature a insdc:Gene ;
                     rdfs:label ?gene_name ;
                     faldo:location ?loc .
            ?loc faldo:begin/faldo:position ?faldo_begin ;
                 faldo:end/faldo:position ?faldo_end .
            FILTER(
              ?faldo_begin != 1 &&
              ! ( ( ?faldo_begin < (?begin - 1000) && ?faldo_end < (?begin - 1000) ) || 
                  ( (?end + 1000) < ?faldo_begin && (?end + 1000) < ?faldo_end ) )
            )
          }
        SPARQL
      end
    end
  end
end
