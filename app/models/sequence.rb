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
      # GGGenome のレスポンスの中で、SPARQL で結果が返ってこなかったもの(= refseq が無いもの)を取得している
      sparql_hits_refseqs =  sparql_results.map {|g| g[:refseq] }.uniq

      sparql_not_hits_gggenome_results = gggenome_response['results'].reject {|genome|
        sparql_hits_refseqs.include?(genome['refseq'])
      }.map(&:symbolize_keys)

      sparql_results + sparql_not_hits_gggenome_results
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
      gggenome_response['results'].each_slice(100).map do |sub_results|
        <<-SPARQL.strip_heredoc
          DEFINE sql:select-option "order"
          PREFIX insdc:  <http://ddbj.nig.ac.jp/ontologies/sequence#>
          PREFIX faldo: <http://biohackathon.org/resource/faldo#>
          PREFIX obo: <http://purl.obolibrary.org/obo/>
          SELECT DISTINCT ?locus_tag ?product ?sequence_ontology ?sequence_ontology_name ?taxonomy ?position ?name ?position_end ?snippet ?snippet_pos ?snippet_end ?strand
          FROM <http://togogenome.org/graph/so/>
          FROM <http://togogenome.org/graph/refseq/>
          WHERE {
            {
              SELECT DISTINCT ?sequence_ontology ?sequence_ontology_name ?taxonomy ?position ?name ?position_end ?snippet ?snippet_pos ?snippet_end ?strand ?f
              WHERE {
                VALUES (?bioproject ?name ?position ?position_end ?refseq ?snippet ?snippet_end ?snippet_pos ?strand ?taxonomy) {
                  #{bind_values(sub_results)}
                }
                FILTER (?feature_position_beg < ?position && ?position < ?feature_position_end && ?feature_position_beg != 1)
                ?sequence insdc:sequence_version ?refseq .
                ?f obo:so_part_of+ ?sequence .
                ?f faldo:location ?loc .
                ?loc faldo:begin ?beg .
                ?beg faldo:position ?feature_position_beg .
                ?loc faldo:end ?end .
                ?end faldo:position ?feature_position_end .
                ?f a ?sequence_ontology .
                ?sequence_ontology rdfs:label ?sequence_ontology_name .
              }
            }
            OPTIONAL {?f insdc:locus_tag ?locus_tag . }
            OPTIONAL {?f insdc:product ?product .}
          }
        SPARQL
      end
    end

    def bind_values(genomes)
      genomes.map {|genome|
        "( #{genome.map {|key, val| %w(position position_end).include?(key) ? "#{val}" : "\"#{val}\"" }.join(' ')} )"
      }.join("\n")
    end
  end
end
