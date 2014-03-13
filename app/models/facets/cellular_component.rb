module Facets
  class CellularComponent < Facets::GeneOntology
    class << self
      def graph_uri
        'http://togogenome.org/graph/go/'
      end

      def root_uri
        'http://purl.obolibrary.org/obo/GO_0005575'
      end
    end
  end
end
