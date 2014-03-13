class Api::GggenomeController < ApplicationController
  def show(gggenome)
    gggenome_keys = gggenome['results'].first.keys

    result = Genome.append_togogenome_attributes(gggenome).map {|binding|
      # GGGenomeの値は キー名と"value"の値のハッシュで表示、togogenome(EP) から取得した値は、"togogenome" キー以下に キー名と"value"の値のハッシュで表示するように
      # ==== Examples
      #  {"position"=>{"type"=>"typed-literal", "datatype"=>"http://www.w3.org/2001/XMLSchema#integer", "value"=>"7480"},
      #   "locus_tag"=>{"type"=>"literal", "value"=>"slr1311"},
      #   "position_end"=>{"type"=>"typed-literal", "datatype"=>"http://www.w3.org/2001/XMLSchema#integer", "value"=>"7496"},
      #   "strand"=>{"type"=>"literal", "value"=>"+"},
      #   "refseq"=>{"type"=>"literal", "value"=>"NC_000911.1"},
      #   "snippet_end"=>{"type"=>"literal", "value"=>"7596"},
      #   "snippet"=>{"type"=>"literal", "value"=>"CCTTCATCGCCGCTCCCCCCGTTGACATCGACGGTATCCGTGAGCCCGTTGCTGGTTCTTTGCTTTACGGTAACAACATCATCTCTGGTGCTGTTGTACCTTCTTCCAACGCTATCGGTTTGCACTTCTACCCCATCTGGGAAGCCGCTTCCTTAGATGAGTGGTTGTACAACGGTGGTCCTTACCAGTTGGTAGTATTCCACTTCCTCATCGGCAT"},
      #   "feature_position_beg"=>{"type"=>"typed-literal", "datatype"=>"http://www.w3.org/2001/XMLSchema#integer", "value"=>"7229"},
      #   "sequence_ontology"=>{"type"=>"uri", "value"=>"http://purl.obolibrary.org/obo/SO_0000704"},
      #   "feature_position_end"=>{"type"=>"typed-literal", "datatype"=>"http://www.w3.org/2001/XMLSchema#integer", "value"=>"8311"},
      #   "snippet_pos"=>{"type"=>"literal", "value"=>"7380"},
      #   "name"=>{"type"=>"literal", "value"=>"Synechocystis sp. PCC 6803 chromosome, complete genome."},
      #   "taxonomy"=>{"type"=>"literal", "value"=>"1148"},
      #   "bioproject"=>{"type"=>"literal", "value"=>"PRJNA57659"}
      #  }
      #
      #  #=> {"position":"7480",
      #       "togogenome":{"locus_tag":"slr1311",
      #                     "feature_position_beg":"7229",
      #                     "sequence_ontology":"http://purl.obolibrary.org/obo/SO_0000704",
      #                     "feature_position_end":"8311"},
      #       "position_end":"7496",
      #       "strand":"+",
      #       "refseq":"NC_000911.1",
      #       "snippet_end":"7596",
      #       "snippet":"CCTTCATCGCCGCTCCCCCCGTTGACATCGACGGTATCCGTGAGCCCGTTGCTGGTTCTTTGCTTTACGGTAACAACATCATCTCTGGTGCTGTTGTACCTTCTTCCAACGCTATCGGTTTGCACTTCTACCCCATCTGGGAAGCCGCTTCCTTAGATGAGTGGTTGTACAACGGTGGTCCTTACCAGTTGGTAGTATTCCACTTCCTCATCGGCAT",
      #       "snippet_pos":"7380",
      #       "name":"Synechocystis sp. PCC 6803 chromosome, complete genome.",
      #       "taxonomy":"1148",
      #       "bioproject":"PRJNA57659"
      #       }
      binding.each_with_object({}) {|(name, term), hash|
        if gggenome_keys.include?(name.to_s)
          hash[name] = term
        else
          (hash['togogenome'] ||= {})[name] = term
        end
      }
    }

    render json: result
  end
end
