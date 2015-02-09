require 'sparql_util'

class Sequence
  include Queryable

  class << self
    def search_sequence_ontologies(sequence)
      genomes = GggenomeSearch.search(sequence)

      sparqls = build_sequence_ontologies_sparqls(genomes)
      sparql_results = sparqls.flat_map {|sparql| query(sparql) }

      genomes.map do |genome|
        so = sparql_results.select {|r| r[:name] == genome.name }
        genome.to_h.merge(
          sequence_ontologies: so.map {|r| {uri: r[:sequence_ontology], name: r[:sequence_ontology_name]}},
          locus_tags: so.map {|r| r[:locus_tag]}.compact.uniq,
          products: so.map {|r| r[:product]}.compact.uniq
        )
      end
    end

    def search_organisms(sequence)
      genomes = GggenomeSearch.search(sequence)

      sparqls = build_organisms_sparqls(genomes)
      sparql_results = sparqls.flat_map {|sparql| query(sparql) }

      sparql_results.map do |results|
        sequence_count = genomes.select {|g| g.taxonomy.to_s == results[:taxonomy_id] }.count
        results.merge(sequence_count: sequence_count)
      end
    end

    private

    def build_sequence_ontologies_sparqls(gggenome)
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
                  #{bind_sequence_ontologies_values(sub_results)}
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

    def build_organisms_sparqls(gggenome)
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
                  #{bind_organisms_values(sub_results)}
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

    def bind_sequence_ontologies_values(genomes)
      genomes.map {|genome|
        "( \"#{genome.name}\" #{genome.position} #{genome.position_end} \"#{genome.refseq}\" \"#{genome.strand}\" )"
      }.join("\n")
    end

    def bind_organisms_values(genomes)
     genomes.map {|genome|
        "tax:#{genome.taxonomy}"
      }.join(" ")
    end
  end
end
