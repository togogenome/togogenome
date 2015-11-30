module Facets
  class GeneOntology < Base
    class << self
      def graph_uri
        SPARQLUtil::ONTOLOGY[:go]
      end

      def search(word)
        sparql = <<-SPARQL.strip_heredoc
          DEFINE sql:select-option "order"
          SELECT ?target ?name ?link ?path ?step ?link_name
          FROM #{graph_uri}
          WHERE {
            {
              SELECT DISTINCT ?target ?name ?link ?path ?step
              WHERE {
                {
                  SELECT DISTINCT ?target ?name ?parent
                  WHERE {
                    FILTER regex(?name, "#{word}", "i") .
                    ?target rdfs:label ?name .
                    FILTER(LANG(?name) = "" || LANGMATCHES(LANG(?name), "en")) .

                    ?target rdfs:subClassOf* ?parent .
                    ?parent rdfs:subClassOf <#{root_uri}> .
                  }
                  LIMIT 15
                }
                ?target rdfs:subClassOf ?parent  OPTION (TRANSITIVE, T_DISTINCT, T_EXISTS, T_DIRECTION 1, T_IN(?target), T_OUT(?parent), T_MIN(0), T_STEP(?target) AS ?link, T_STEP("path_id") AS ?path , T_STEP('step_no') AS ?step ) .
              }
            }
            ?link rdfs:label ?link_name .
            FILTER(LANG(?link_name) = "" || LANGMATCHES(LANG(?link_name), "en")) .
          }
        SPARQL

        self.query(sparql).sort_by {|b| b[:name] }.group_by {|b|
          b[:target]
        }.map {|uri, vals|
          target_vals = vals.group_by {|b| b[:path] }.sort_by {|path, vals| -path.to_i }.first.last.sort_by {|b| -b[:step].to_i }.tap(&:pop)

          desc = target_vals.map {|v| v[:link_name] }.push(vals.first[:name]).join(' > ')
          parents = target_vals.map {|v| v[:link] }.push(uri)
          self.new(id: uri, name: vals.first[:name], description: desc, ancestor: parents)
        }
      end
    end
  end
end
