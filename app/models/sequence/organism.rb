require 'sparql_util'

module Sequence
  class Organism
    include Queryable

    class << self
      def search(sequence)
        genomes = Sequence::GggenomeSearch.search(sequence)

        sparqls = build_sparqls(genomes)
        results = sparqls.flat_map {|sparql| query(sparql) }

        results.map do |result|
          sequence_count = genomes.select {|g| g.taxonomy.to_s == result[:taxonomy_id] }.count
          result.merge(sequence_count: sequence_count)
        end
      end

      def build_sparqls(gggenome)
        # slice の理由
        # gggenome での検索結果が多い時、それらをまとめて1つのSPARQL にすると、
        # SPARQLのサーバで 'error code 414: uri too large' にひっかかってしまうため Query を分割している
        gggenome.each_slice(300).map do |sub_results|
          <<-SPARQL.strip_heredoc
            DEFINE sql:select-option "order"
            PREFIX tax: <http://identifiers.org/taxonomy/>
            SELECT DISTINCT (REPLACE(STR(?taxonomy),"http://identifiers.org/taxonomy/","") AS ?taxonomy_id) ?taxonomy_name ?category ?category_name ?sub_category ?sub_category_name
            FROM #{SPARQLUtil::ONTOLOGY[:taxonomy]}
            WHERE {
              VALUES ?taxonomy  {
                  #{bind_values(sub_results)}
              }
              ?taxonomy rdfs:label ?taxonomy_name .

              ?taxonomy  rdfs:subClassOf* ?sub_category  .
              ?category rdfs:subClassOf <http://identifiers.org/taxonomy/131567> .
              ?sub_category rdfs:subClassOf ?category .

              ?category rdfs:label ?category_name .
              ?sub_category rdfs:label ?sub_category_name .
            } ORDER BY ?category ?sub_category
          SPARQL
        end
      end

      private

      def bind_values(genomes)
        genomes.map {|genome| "tax:#{genome.taxonomy}" }.join(" ")
      end
    end
  end
end
