class Virus
  include Queryable

  class << self
    def find(id)
      sparql = <<-SPARQL.strip_heredoc
        SELECT DISTINCT ?name
        FROM <http://togogenome.org/graph/taxonomy>
        WHERE {
          <http://identifiers.org/taxonomy/#{id}> rdfs:label ?name .
        }
      SPARQL

      OpenStruct.new(query(sparql).first)
    end
  end
end
