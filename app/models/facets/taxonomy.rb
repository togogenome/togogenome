# coding: utf-8

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
    end
  end
end
