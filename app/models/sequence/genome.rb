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
            )
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
    end
  end
end
