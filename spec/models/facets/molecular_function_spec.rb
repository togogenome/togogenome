require 'spec_helper'
module Facets
  describe MolecularFunction do
    describe 'self.search' do
      context 'with argment "metal ion binding"' do
        subject { Facets::MolecularFunction.search('metal ion binding') }

        it do
         should ==  [
            Facets::MolecularFunction.new(
              ancestor: ["http://purl.obolibrary.org/obo/GO_0005488", "http://purl.obolibrary.org/obo/GO_0043167", "http://purl.obolibrary.org/obo/GO_0043169", "http://purl.obolibrary.org/obo/GO_0046872", "http://purl.obolibrary.org/obo/GO_0031420"],
              description: "binding > ion binding > cation binding > metal ion binding > alkali metal ion binding",
              hits: nil,
              id: "http://purl.obolibrary.org/obo/GO_0031420",
              name: "alkali metal ion binding"
            ),
            Facets::MolecularFunction.new(
              ancestor: ["http://purl.obolibrary.org/obo/GO_0005488", "http://purl.obolibrary.org/obo/GO_0043167", "http://purl.obolibrary.org/obo/GO_0043169", "http://purl.obolibrary.org/obo/GO_0046872"],
              description: "binding > ion binding > cation binding > metal ion binding",
              hits: nil,
              id: "http://purl.obolibrary.org/obo/GO_0046872",
              name: "metal ion binding"
            ),
            Facets::MolecularFunction.new(
              ancestor: ["http://purl.obolibrary.org/obo/GO_0005488", "http://purl.obolibrary.org/obo/GO_0043167", "http://purl.obolibrary.org/obo/GO_0043169", "http://purl.obolibrary.org/obo/GO_0046872", "http://purl.obolibrary.org/obo/GO_0046914"],
              description: "binding > ion binding > cation binding > metal ion binding > transition metal ion binding",
              hits: nil,
              id: "http://purl.obolibrary.org/obo/GO_0046914",
              name: "transition metal ion binding"
            )
          ]
        end
      end

      context 'with argment "cellular metal"' do
        subject { Facets::MolecularFunction.search('cellular metal') }

        it { should be_empty}
      end
    end
  end
end
