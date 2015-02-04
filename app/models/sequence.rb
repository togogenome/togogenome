require 'sparql_util'

class Sequence
  include Queryable

  class << self
    def search(sequence)
      gggenome_response = search_gggenome(sequence)

      raise StandardError, "[GGGenome Error] #{gggenome_response['error']}" unless gggenome_response['error'] == 'none'

      append_togogenome_attributes(gggenome_response)
    end

    def append_togogenome_attributes(gggenome_response)
      sparqls = build_sparqls(gggenome_response)
      sparql_results = sparqls.flat_map {|sparql|
        result = query(sparql)
      }

      gggenome_response['results'].map do |genome|
        so = sparql_results.select {|r| r[:name] == genome['name'] }
        genome.merge(
          {
            'sequence_ontologies' => so.map {|r| {'uri' => r[:sequence_ontology], 'name' => r[:sequence_ontology_name]}},
            'locus_tags'          => so.map {|r| r[:locus_tag]}.compact.uniq,
            'products'            => so.map {|r| r[:product]}.compact.uniq
          }
        )
      end
    end

    private

    def search_gggenome(sequence, url = 'http://gggenome.dbcls.jp/prok', format = 'json')
      client = HTTPClient.new
      ret = client.get_content("#{url}/#{sequence}.#{format}")
      JSON.parse(ret)
    end

    def build_sparqls(gggenome_response)
      # slice(100) の理由
      # 1. gggenome での検索結果が多い時、それらをまとめて1つのSPARQL にすると、
      #    SPARQLのサーバで 'error code 414: uri too large' にひっかかってしまうため Query を分割している
      # 2. Endpoint 側(hhttp://ep.dbcls.jp/sparql7os) SPARQLに対してタイムアウトが発生し、エラーが帰って来た
      gggenome_response['results'].each_slice(300).map do |sub_results|
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

    def bind_values(genomes)
      genomes.map {|genome|
        "( #{genome.select {|k, _v| %w(name position position_end refseq strand).include?(k) }.map {|key, val| %w(position position_end).include?(key) ? "#{val}" : "\"#{val}\"" }.join(' ')} )"
      }.join("\n")
    end
  end
end
