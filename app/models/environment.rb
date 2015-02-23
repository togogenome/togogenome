require 'sparql_util'

class Environment
  include Queryable

  class << self
    def find(id)
      sparql = <<-SPARQL.strip_heredoc
        SELECT DISTINCT ?name
        FROM #{SPARQLUtil::ONTOLOGY[:meo]}
        WHERE {
          <http://purl.jp/bio/11/meo/#{id}> rdfs:label ?name .
          FILTER(LANG(?name) = "" || LANGMATCHES(LANG(?name), "en"))
        }
      SPARQL

      OpenStruct.new(query(sparql).first)
    end
  end
end
