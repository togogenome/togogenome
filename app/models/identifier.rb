class Identifier
  include Queryable

  class << self
    def convert(identifiers, db_names)
      sparql_vars = db_names.count.times.map {|i| "?node#{i}" }.join(' ')

      input_database, *convert_databases = db_names
      values = identifiers.split(/\r\n|\r|\n/).map {|identifier| "<http://identifiers.org/#{input_database}/#{identifier}>"}.join(' ')

      sparql =<<-SPARQL.strip_heredoc
        DEFINE sql:select-option "order"
        SELECT DISTINCT #{sparql_vars}
        FROM <http://togogenome.org/graph/edgestore/>
        WHERE {
          VALUES ?node0 { #{values} }
          #{mapping(convert_databases)}
       }
      SPARQL

      query(sparql)
    end

    def sample(db_names)
      sparql_vars = db_names.count.times.map {|i| "?node#{i}" }.join(' ')

      input_database, *convert_databases = db_names

      sparql =<<-SPARQL.strip_heredoc
        DEFINE sql:select-option "order"
        SELECT DISTINCT #{sparql_vars}
        FROM <http://togogenome.org/graph/edgestore/>
        WHERE {
          ?node0 rdf:type <http://identifiers.org/#{input_database}/> .
          #{mapping(convert_databases)}
        }
        LIMIT 2
      SPARQL

      query(sparql)
    end

    private

    def mapping(databases)
      databases.map.with_index {|db_name, i|
        <<-SPARQL
          ?node#{i} ?seeAlso ?node#{i.succ} .
          ?node#{i.succ} rdf:type <http://identifiers.org/#{db_name}/> .
        SPARQL
      }.join("\n")
    end
  end
end
