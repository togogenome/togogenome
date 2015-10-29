module Facets
  class Taxonomy < Base
    class << self
      def graph_uri
        SPARQLUtil::ONTOLOGY[:taxonomy]
      end

      def root_uri
        'http://identifiers.org/taxonomy/131567'
      end

      def filter
        "FILTER(?parent != <http://identifiers.org/taxonomy/1> && ?parent != <#{root_uri}>)"
      end

      # Facet内で文字列検索
      def search(word)
        sparql = <<-SPARQL.strip_heredoc
          SELECT ?target ?name ?parent ?parent_name ?step
          WHERE {
            GRAPH <http://togogenome.org/graph/taxonomy> {
              SELECT ?target ?name
              WHERE {
                FILTER regex(?name, "#{word}", "i") .
                ?target rdfs:label ?name .
                FILTER(LANG(?name) = "" || LANGMATCHES(LANG(?name), "en")) .
              }
              LIMIT 16
            }
            GRAPH <http://togogenome.org/graph/taxonomy_lite> {
              FILTER EXISTS { ?target rdfs:subClassOf ?_parent } .
              ?target rdfs:subClassOf ?parent  OPTION (TRANSITIVE, T_DIRECTION 1, T_MIN(0), T_STEP("step_no") AS ?step) .
            }
            GRAPH <http://togogenome.org/graph/taxonomy> {
              ?parent rdfs:label ?parent_name .
              FILTER(LANG(?parent_name) = "" || LANGMATCHES(LANG(?parent_name), "en")) .
              #{filter}
            }
          }
        SPARQL

        self.query(sparql).sort_by {|b| b[:name] }.group_by {|b|
          b[:target]
        }.map {|uri, vals|
          sort_vals = vals.sort_by {|v| -v[:step].to_i }
          desc = sort_vals.map {|v| v[:parent_name] }.join(' > ')
          parents = sort_vals.map {|v| v[:parent] }
          self.new(id: uri, name: vals.first[:name], description: desc, ancestor: parents)
        }
      end
    end
  end
end
