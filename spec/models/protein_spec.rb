# coding: utf-8

require 'spec_helper'

describe Protein do
  describe 'self.search' do
    context "複数件取得できる検索を実行" do
      context "初期表示" do
        subject {
          Protein.search('', '', '', '', '', '')
        }

        it {
          subject.map(&:id).should =~ %w(A9MT07 A9MV74 A9MVK2 A9MVV3 A9MW32 A9MWZ0 A9MX60 A9MXA8 A9MXA9 A9MY97 A9MYG7 A9MZ19 A9MZM1 A9MZR1 A9MZS9 A9N0J1 A9N0T3 A9N0T5 A9N202 A9N4C4 A9N4N4 A9N6Y0 A9N709 A9N740 A9N7U4)
        }
      end

      context "サンプルの例" do
        # Environment:       "fresh water"  (http://purl.jp/bio/11/meo/MEO_0000038)
        # Taxonomy:          "Nostocales"  (http://identifiers.org/taxonomy/1161)
        # BiologicalProcess: "cellular nitrogen compound metabolic process" (http://purl.obolibrary.org/obo/GO_0034641)
        # MolecularFunction: "metal ion binding"  (http://purl.obolibrary.org/obo/GO_0046872)
        # CellularComponent: "cytoplasm"  (http://purl.obolibrary.org/obo/GO_0005737)
        # Phenotype:         "Motile"  (http://purl.jp/bio/01/mpo#MPO_02001)

        subject {
          Protein.search('http://purl.jp/bio/11/meo/MEO_0000038', 'http://identifiers.org/taxonomy/1161', 'http://purl.obolibrary.org/obo/GO_0034641', 'http://purl.obolibrary.org/obo/GO_0046872', 'http://purl.obolibrary.org/obo/GO_0005737', 'http://purl.jp/bio/01/mpo#MPO_02001')
        }

        it {
          subject.map(&:id).should =~ %w(P58711 Q8YLL1 Q8YMH5 Q8YMJ0 Q8YN19 Q8YN47 Q8YN94 Q8YN97 Q8YPW9 Q8YQD7 Q8YQT0 Q8YRP2 Q8YUA5 Q8YUD4 Q8YUI2 Q8YXA3 Q8YXJ1 Q8YXW5 Q8YXY3 Q8YYV8 Q8YZV0 Q8Z023 Q8Z032 Q8Z0F5 Q8Z0I6)
        }
      end

      context "1階層目 の組み合わせ検索" do
        # Environment:       "hydrosphere"
        # Taxonomy:          "Bacteria"
        # BiologicalProcess: "biological regulation"
        # MolecularFunction: "binding"
        # CellularComponent: "cell part"
        # Phenotype:         "Motility"

        subject {
          Protein.search('http://purl.jp/bio/11/meo/MEO_0000004', 'http://identifiers.org/taxonomy/2', 'http://purl.obolibrary.org/obo/GO_0065007', 'http://purl.obolibrary.org/obo/GO_0005488', 'http://purl.obolibrary.org/obo/GO_0044464', 'http://purl.jp/bio/01/mpo#MPO_02000')
        }

        it {
          subject.map(&:id).should =~ %w(A3D3H2 A3DAR2 A4G9W6 A5GT42 A5VF26 A7N0Z7 A8G3X7 I0LFE5 I0LGE0 I0LGI0 I0LGQ4 I0LHZ9 I0LJ10 I0LJ88 I0LJZ2 I0LKW2 I0LLB1 I0LLC0 I0LLC1 I0LLC6 I0LLV2 I0LLY6 I0LN44 I0LNQ8 Q8NTE1)
        }
      end

      context "GOが絞り込み対象に無い検索" do
        # Environment:       "hydrosphere"
        # Taxonomy:          "Bacteria"
        # BiologicalProcess: ""
        # MolecularFunction: ""
        # CellularComponent: ""
        # Phenotype:         "Motility"

        subject {
          Protein.search('http://purl.jp/bio/11/meo/MEO_0000004', 'http://identifiers.org/taxonomy/2', '', '', '', 'http://purl.jp/bio/01/mpo#MPO_02000')
        }

        it {
          subject.map(&:id).should =~ %w(G2Z088 G2Z0N6 G2Z0W1 G2Z150 G2Z176 G2Z1Y9 G2Z2H6 G2Z2J7 G2Z329 G2Z347 G2Z352 G2Z3P5 G2Z3Z4 G2Z414 G2Z454 G2Z4G2 G2Z4J8 G2Z4Y4 G2Z5R6 G2Z698 G2Z6C6 G2Z701 G2Z760 G2Z7A2 G2Z7W4)
        }
      end

      context "GO, Taxが絞り込み対象に無い検索" do
        # Environment:       "hydrosphere"
        # Taxonomy:          ""
        # BiologicalProcess: ""
        # MolecularFunction: ""
        # CellularComponent: ""
        # Phenotype:         "Motility"

        subject {
          Protein.search('http://purl.jp/bio/11/meo/MEO_0000004', '', '', '', '', 'http://purl.jp/bio/01/mpo#MPO_02000')
        }

        it {
          subject.map(&:id).should =~ %w(A8G2K6 A8G2K9 A8G2L3 A8G2Q0 A8G2X2 A8G2Y3 A8G3P9 A8G3Y9 A8G4T2 A8G5G6 A8G6B7 A8G6V1 A8G6V2 A8G710 A8G714 Q79VG7 Q8NNJ0 Q8NQ07 Q8NQV2 Q8NQV3 Q8NST4 Q8NT20 Q8NT29 Q9K5E4 Q9X4N0)
        }
      end
    end

    context "0件となる検索も正しく動くこと" do
      context "対応の GO と関連はあるが、他の Uniprot とのSPARQL で検索が0件になる" do
        # CellularComponent: "cell junction"  (http://purl.obolibrary.org/obo/GO_0030054)

        subject {
          Protein.search('', '', '', '', 'http://purl.obolibrary.org/obo/GO_0030054', '')
        }

        it { should be_empty }
      end
    end
  end
end
