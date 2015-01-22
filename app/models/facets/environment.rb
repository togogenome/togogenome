module Facets
  class Environment < Base
    class << self
      def graph_uri
        SPARQLUtil::ONTOLOGY[:meo]
      end

      def root_uri
        'http://www.w3.org/2002/07/owl#Thing'
      end
    end
  end
end
