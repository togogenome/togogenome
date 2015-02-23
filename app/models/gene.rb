require 'sparql_util'

class Gene
  include Queryable

  class << self
    def find(id)
      sparql = <<-SPARQL.strip_heredoc
        DEFINE sql:select-option "order"
        #{SPARQLUtil::PREFIX[:up]}

        SELECT DISTINCT ?name
        WHERE {
          GRAPH #{SPARQLUtil::ONTOLOGY[:tgup]} {
            <http://togogenome.org/gene/#{id}> rdfs:seeAlso ?uniprot_id .
            ?uniprot_id rdf:type <http://identifiers.org/uniprot> ;
                        rdfs:seeAlso ?uniprot_up .
          }
          GRAPH #{SPARQLUtil::ONTOLOGY[:uniprot]} {
            ?uniprot_up up:recommendedName/up:fullName ?name
          }
        }
      SPARQL

      OpenStruct.new(query(sparql).first)
    end
  end
end
