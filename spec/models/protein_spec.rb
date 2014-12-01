# coding: utf-8

require 'spec_helper'

describe Protein do
  describe 'self.search' do
    context "複数件取得できる検索を実行" do
      context "初期表示" do
        subject {
          Protein.search()
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
          args = {
            meo_id: 'http://purl.jp/bio/11/meo/MEO_0000038',
            tax_id: 'http://identifiers.org/taxonomy/1161',
            bp_id: 'http://purl.obolibrary.org/obo/GO_0034641',
            mf_id: 'http://purl.obolibrary.org/obo/GO_0046872',
            cc_id: 'http://purl.obolibrary.org/obo/GO_0005737',
            mpo_id: 'http://purl.jp/bio/01/mpo#MPO_02001'
          }

          Protein.search(args)
        }

        it {
          subject.map(&:id).should =~ %w(O52749 P45480 P58711 Q8YLN3 Q8YMT4 Q8YMZ0 Q8YN49 Q8YN91 Q8YP11 Q8YP68 Q8YPR8 Q8YPT4 Q8YPV5 Q8YQB2 Q8YQR8 Q8YQV0 Q8YQZ0 Q8YQZ3 Q8YWS8 Q8YYW0 Q8YZX0 Q8Z068 Q8Z074 Q8Z0F5 Q8Z0I6)
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
          args = {
            meo_id: 'http://purl.jp/bio/11/meo/MEO_0000004',
            tax_id: 'http://identifiers.org/taxonomy/2',
            bp_id: 'http://purl.obolibrary.org/obo/GO_0065007',
            mf_id: 'http://purl.obolibrary.org/obo/GO_0005488',
            cc_id: 'http://purl.obolibrary.org/obo/GO_0044464',
            mpo_id: 'http://purl.jp/bio/01/mpo#MPO_02000'
          }

          Protein.search(args)
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
          args = {
            meo_id: 'http://purl.jp/bio/11/meo/MEO_0000004',
            tax_id: 'http://identifiers.org/taxonomy/2',
            mpo_id: 'http://purl.jp/bio/01/mpo#MPO_02000'
          }

          Protein.search(args)
        }

        it {
          subject.map(&:id).should =~ %w(G2YZW4 G2Z0V5 G2Z104 G2Z120 G2Z1A9 G2Z1E3 G2Z1E8 G2Z1P2 G2Z1X9 G2Z259 G2Z2E9 G2Z3W4 G2Z404 G2Z464 G2Z5C9 G2Z5X6 G2Z643 G2Z673 G2Z690 G2Z6A7 G2Z6J1 G2Z6Q1 G2Z7E8 G2Z7H5 G2Z7N5)
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
          args = {
            meo_id: 'http://purl.jp/bio/11/meo/MEO_0000004',
            mpo_id: 'http://purl.jp/bio/01/mpo#MPO_02000'
          }

          Protein.search(args)
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
          Protein.search(cc_id: 'http://purl.obolibrary.org/obo/GO_0030054')
        }

        it { should be_empty }
      end
    end
  end
end
