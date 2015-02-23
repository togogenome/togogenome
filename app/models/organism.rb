require 'sparql_util'

class Organism
  include Queryable

  class << self
    def find(id)
      sparql = <<-SPARQL.strip_heredoc
        SELECT DISTINCT ?name
        FROM #{SPARQLUtil::ONTOLOGY[:taxonomy]}
        WHERE {
          <http://identifiers.org/taxonomy/#{id}> rdfs:label ?name .
        }
      SPARQL

      OpenStruct.new(query(sparql).first)
    end
  end
end
