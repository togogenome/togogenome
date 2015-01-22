require 'sparql_util'

module Facets
  class Base
    include ActiveAttr::Model
    include Queryable

    attribute :name
    attribute :id
    attribute :hits
    attribute :description
    attribute :ancestor

    def children
      sparql = <<-SPARQL.strip_heredoc
        SELECT ?target ?name (COUNT(?name) AS ?hits)
        FROM #{self.class.graph_uri}
        WHERE {
          ?target rdfs:subClassOf <#{self.id}> ;
                  rdfs:label ?name .
          FILTER(LANG(?name) = "" || LANGMATCHES(LANG(?name), "en")) .
          OPTIONAL {
            ?sub rdfs:subClassOf ?target .
          }
        }
        GROUP BY ?target ?name
      SPARQL

      # ORDER BY を付けると結果が変わったぞー。 id: <http://identifiers.org/taxonomy/1142>, GRAPH: <http://togogenome.org/graph/taxonomy/> で試したところ
      self.class.query(sparql).map { |h|
        self.class.new(id: h[:target].to_s, name: h[:name].to_s, hits: h[:hits].to_i)
      }.sort_by {|f| f.name }
    end

    def as_json(*)
      {
        id:   self.id,
        name: self.name,
        hits: self.hits
      }
    end

    class << self
      def lookup(facet_name)
        "facets/#{facet_name}".tableize.classify.constantize
      end

      def root
        self.new(id: self.root_uri, name: 'All')
      end

      # Facet内で文字列検索
      def search(word)
        sparql = <<-SPARQL.strip_heredoc
          SELECT ?target ?name ?parent ?parent_name ?step
          FROM #{self.graph_uri}
          WHERE {
            {
              SELECT ?target ?name
              WHERE {
                FILTER regex(?name, "#{word}", "i") .
                ?target rdfs:label ?name .
                FILTER(LANG(?name) = "" || LANGMATCHES(LANG(?name), "en")) .
              }
              LIMIT 16
            }
            ?target rdfs:subClassOf ?parent  OPTION (TRANSITIVE, T_DIRECTION 1, T_MIN(0), T_STEP("step_no") AS ?step) .
            ?parent rdfs:label ?parent_name .
            FILTER(LANG(?parent_name) = "" || LANGMATCHES(LANG(?parent_name), "en")) .
            #{self.filter}
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

      def filter
        ''
      end
    end
  end
end
