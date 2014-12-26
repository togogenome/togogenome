module Facets
  class BiologicalProcess < Facets::GeneOntology
    class << self
      def root_uri
        'http://purl.obolibrary.org/obo/GO_0008150'
      end
    end
  end
end
