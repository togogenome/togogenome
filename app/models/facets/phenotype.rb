module Facets
  class Phenotype < Base
    class << self
      def graph_uri
        SPARQLUtil::ONTOLOGY[:mpo]
      end

      def root_uri
        'http://purl.jp/bio/01/mpo#MPO_00000'
      end

      def filter
        "FILTER( ?parent != <#{root_uri}> )"
      end
    end
  end
end
