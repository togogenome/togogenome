module Facets
  class BiologicalProcess < Facets::GeneOntology
    class << self
      def graph_uri
        'http://togogenome.org/graph/go/'
      end

      def root_uri
        'http://purl.obolibrary.org/obo/GO_0008150'
      end
    end
  end
end
