module Facets
  class Environment < Base
    class << self
      def graph_uri
        'http://togogenome.org/graph/meo'
      end

      def root_uri
        'http://www.w3.org/2002/07/owl#Thing'
      end
    end
  end
end
