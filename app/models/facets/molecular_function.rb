module Facets
  class MolecularFunction < Facets::GeneOntology
    class << self
      def graph_uri
        'http://togogenome.org/graph/go/'
      end

      def root_uri
        'http://purl.obolibrary.org/obo/GO_0003674'
      end
    end
  end
end
