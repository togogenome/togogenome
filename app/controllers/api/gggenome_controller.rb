class Api::GggenomeController < ApplicationController
  def show(gggenome)
    genomes = gggenome['results'].map {|r| OpenStruct.new(r) }
    sparqls = Sequence::Genome.build_sparqls(genomes)
    sparql_results = sparqls.flat_map {|sparql| Sequence::Genome.query(sparql) }

    results = genomes.map do |genome|
      so = sparql_results.select {|r| r[:name] == genome.name }

      genome.to_h.merge(
        togogenome: {
          sequence_ontologies: so.map {|r| {uri: r[:sequence_ontology], name: r[:sequence_ontology_name]} },
          locus_tags: so.map {|r| r[:locus_tag] }.compact.uniq,
          products: so.map {|r| r[:product] }.compact.uniq
        }
      )
    end

    render json: results
  end
end
