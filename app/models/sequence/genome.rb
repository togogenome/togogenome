require 'sparql_util'

module Sequence
  class Genome
    include Queryable

    class << self
      def search(sequence)
        genomes = Sequence::GggenomeSearch.search(sequence)

        # sparqls = build_sparqls(genomes)
        sparqls = next_gene_build_sparqls(genomes)
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

      # def build_sparqls(gggenome)
      #   gggenome.each_slice(300).map do |sub_results|
      #     <<-SPARQL.strip_heredoc
      #       DEFINE sql:select-option "order"
      #       #{SPARQLUtil::PREFIX[:insdc]}
      #       #{SPARQLUtil::PREFIX[:faldo]}
      #       #{SPARQLUtil::PREFIX[:obo]}
      #       #{SPARQLUtil::PREFIX[:refseq]}
      #
      #       SELECT ?refseq_uri ?seq_label ?togogenome ?gene_name ?faldo_begin ?faldo_end
      #       FROM #{SPARQLUtil::ONTOLOGY[:tgup]}
      #       FROM #{SPARQLUtil::ONTOLOGY[:refseq]}
      #       {
      #         {
      #           SELECT ?refseq_uri (MAX(?faldo_end) AS ?max_pos)
      #           FROM #{SPARQLUtil::ONTOLOGY[:tgup]}
      #           FROM #{SPARQLUtil::ONTOLOGY[:refseq]}
      #           WHERE {
      #             VALUES (?refseq_uri ?begin ?end ?dummy1 ?dummy2) {
      #              #{bind_values(sub_results)}
      #             }
      #             ?refseq_uri insdc:sequence ?seq .
      #             ?feature obo:so_part_of ?seq;
      #               rdfs:label ?gene_name;
      #               faldo:location ?loc.
      #             ?loc faldo:begin/faldo:position ?faldo_begin;
      #               faldo:end/faldo:position ?faldo_end.
      #             FILTER(
      #               ?faldo_begin != 1 && (?faldo_begin < ?begin && ?faldo_end < ?begin)
      #             )
      #           } GROUP BY ?refseq_uri
      #         }
      #         ?refseq_uri insdc:sequence ?seq ;
      #           rdfs:label ?seq_label .
      #         ?feature obo:so_part_of ?seq;
      #           rdfs:label ?gene_name;
      #           faldo:location ?loc.
      #         ?loc faldo:begin/faldo:position ?faldo_begin;
      #           faldo:end/faldo:position ?faldo_end.
      #         ?togogenome skos:exactMatch ?feature .
      #         FILTER( ?faldo_begin = ?max_pos || ?faldo_end = ?max_pos)
      #       }
      #     SPARQL
      # end
      def next_gene_build_sparqls(gggenome)
        gggenome.each_slice(300).map do |sub_results|
          <<-SPARQL.strip_heredoc
            DEFINE sql:select-option "order"
            #{SPARQLUtil::PREFIX[:insdc]}
            #{SPARQLUtil::PREFIX[:faldo]}
            #{SPARQLUtil::PREFIX[:obo]}
            #{SPARQLUtil::PREFIX[:refseq]}

            SELECT ?refseq_uri ?seq_label ?togogenome ?gene_name ?faldo_begin ?faldo_end
            FROM #{SPARQLUtil::ONTOLOGY[:tgup]}
            FROM #{SPARQLUtil::ONTOLOGY[:refseq]}
            {
              {
                SELECT ?refseq_uri (MIN(?faldo_begin) AS ?min_pos)
                FROM #{SPARQLUtil::ONTOLOGY[:tgup]}
                FROM #{SPARQLUtil::ONTOLOGY[:refseq]}
                WHERE {
                  VALUES (?refseq_uri ?begin ?end ?dummy1 ?dummy2) {
                   #{bind_values(sub_results)}
                  }
                  ?refseq_uri insdc:sequence ?seq .
                  ?feature obo:so_part_of ?seq;
                    rdfs:label ?gene_name;
                    faldo:location ?loc.
                  ?loc faldo:begin/faldo:position ?faldo_begin;
                    faldo:end/faldo:position ?faldo_end.
                  FILTER(
                    ?faldo_begin != 1 && (?end < ?faldo_begin && ?end < ?faldo_end)
                  )
                } GROUP BY ?refseq_uri
              }
              ?refseq_uri insdc:sequence ?seq ;
                rdfs:label ?seq_label .
              ?feature obo:so_part_of ?seq;
                rdfs:label ?gene_name;
                faldo:location ?loc.
              ?loc faldo:begin/faldo:position ?faldo_begin;
                faldo:end/faldo:position ?faldo_end.
              ?togogenome skos:exactMatch ?feature .
              FILTER( ?faldo_begin = ?min_pos || ?faldo_end = ?min_pos)
            }
          SPARQL
        end
      end

      private

      def bind_values(genomes)
        genomes.map { |genome|
          "( refseq:#{genome.refseq} #{genome.position} #{genome.position_end} \"#{genome.name}\" \"#{genome.strand}\" )"
        }.join("\n")
      end
    end
  end
end
