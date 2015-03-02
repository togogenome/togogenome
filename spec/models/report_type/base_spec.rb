# coding: utf-8

require 'spec_helper'

describe ReportType::Base do
  describe "self.count" do
    context "初期表示の場合" do
      context "Gene" do
        subject { ReportType::Gene.count() }
        it { subject.should eq("1893802") }
      end

      context "Organism" do
        subject { ReportType::Organism.count() }
        it { subject.should eq("3189") }
      end

      context "Phenotype" do
        subject { ReportType::Phenotype.count() }
        it { subject.should eq("276") }
      end

      context "Environment" do
        subject { ReportType::Environment.count() }
        it { subject.should eq("781") }
      end
    end

    context "サンプルの例での検索の場合" do
      before {
        # Environment:       "fresh water"  (http://purl.jp/bio/11/meo/MEO_0000038)
        # Taxonomy:          "Nostocales"  (http://identifiers.org/taxonomy/1161)
        # BiologicalProcess: "cellular nitrogen compound metabolic process" (http://purl.obolibrary.org/obo/GO_0034641)
        # MolecularFunction: "metal ion binding"  (http://purl.obolibrary.org/obo/GO_0046872)
        # CellularComponent: "cytoplasm"  (http://purl.obolibrary.org/obo/GO_0005737)
        # Phenotype:         "Motile"  (http://purl.jp/bio/01/mpo#MPO_02001)

        @args = {
          meo_id: 'http://purl.jp/bio/11/meo/MEO_0000038',
          tax_id: 'http://identifiers.org/taxonomy/1161',
          bp_id: 'http://purl.obolibrary.org/obo/GO_0034641',
          mf_id: 'http://purl.obolibrary.org/obo/GO_0046872',
          cc_id: 'http://purl.obolibrary.org/obo/GO_0005737',
          mpo_id: 'http://purl.jp/bio/01/mpo#MPO_02001'
        }
      }

      context "Gene" do
        subject { ReportType::Gene.count(@args) }
        it { subject.should eq("50") }
      end

      context "Organism" do
        subject { ReportType::Organism.count(@args) }
        it { subject.should eq("1") }
      end

      context "Phenotype" do
        subject { ReportType::Phenotype.count(@args) }
        it { subject.should eq("1") }
      end

      context "Environment" do
        subject { ReportType::Environment.count(@args) }
        it { subject.should eq("1") }
      end
    end
  end
end
