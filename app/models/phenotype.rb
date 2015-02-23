require 'sparql_util'

class Phenotype
  include Queryable

  class << self
    def find(id)
      sparql = <<-SPARQL.strip_heredoc
        SELECT DISTINCT ?name
        FROM #{SPARQLUtil::ONTOLOGY[:mpo]}
        WHERE {
          <http://purl.jp/bio/01/mpo##{id}> rdfs:label ?name .
          FILTER(LANG(?name) = "" || LANGMATCHES(LANG(?name), "en"))
        }
      SPARQL

      OpenStruct.new(query(sparql).first)
    end
  end
end
