require 'sparql_util'

class Identifier
  include Queryable

  class << self
    def count(identifiers, db_names)
      sparql = <<-SPARQL.strip_heredoc
        DEFINE sql:select-option "order"
        SELECT COUNT (?node0) AS ?hits_count
        WHERE {
          #{build_convert_sparql(identifiers, db_names)}
        }
      SPARQL

      query(sparql).first[:hits_count].to_i
    end

    def convert(identifiers, db_names, limit=100, offset=0)
      sparql = <<-SPARQL.strip_heredoc
        DEFINE sql:select-option "order"

        #{build_convert_sparql(identifiers, db_names)}

        LIMIT #{limit}
        OFFSET #{offset}
      SPARQL

      query(sparql)
    end

    def sample(db_names)
      input_database, *convert_databases = db_names

      sparql = <<-SPARQL.strip_heredoc
        DEFINE sql:select-option "order"
        SELECT DISTINCT #{select_target(db_names)}
        FROM #{SPARQLUtil::ONTOLOGY[:edgestore]}
        WHERE {
          ?node0 rdf:type <http://identifiers.org/#{input_database}> .
          #{mapping(convert_databases)}
        }
        LIMIT 2
      SPARQL

      query(sparql).uniq_by {|i| i[:node0] }
    end

    private

    def build_convert_sparql(identifiers, db_names)
      input_database, *convert_databases = db_names
      values = identifiers.map {|identifier| "<http://identifiers.org/#{input_database}/#{identifier}>" }.join(' ')

      <<-SPARQL.strip_heredoc
        SELECT DISTINCT #{select_target(db_names)}
        FROM #{SPARQLUtil::ONTOLOGY[:edgestore]}
        WHERE {
          VALUES ?node0 { #{values} }
          #{mapping(convert_databases)}
        }
      SPARQL
    end

    def select_target(db_names)
      db_names.count.times.map {|i| "?node#{i}" }.join(' ')
    end

    def mapping(databases)
      databases.map.with_index {|db_name, i|
        <<-SPARQL
          ?node#{i} ?seeAlso ?node#{i.succ} .
          ?node#{i.succ} rdf:type <http://identifiers.org/#{db_name}> .
        SPARQL
      }.join("\n")
    end
  end
end
