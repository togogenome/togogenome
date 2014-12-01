class Taxonomy
  def initialize(uri, name)
    @uri, @name = uri, name
    @id = uri.split('/').last
  end

  attr_reader :id, :uri, :name
end

class Gene
  def initialize(togogenome_uri)
    @togogenome_uri = togogenome_uri
    @id = togogenome_uri.split('/').last
  end

  attr_reader :id, :togogenome_uri
end

class GeneOntology
  def initialize(quick_go_uri, name)
    @uri, @name = quick_go_uri, name
    @id = uri.split('id=').last
  end

  attr_reader :id, :uri, :name
end

class Environment
  def initialize(id, name)
    @id, @name = id, name
  end

  attr_reader :id, :name
end

class Phenotype
  def initialize(id, name)
    @id, @name = id, name
  end

  attr_reader :id, :name
end

class Protein
  include Queryable
  include ProteinSparqlBuilder

  class << self
    def count(meo_id: '', tax_id: '', bp_id: '', mf_id: '', cc_id: '', mpo_id: '')
      sparql  = count_sparql(meo_id, tax_id, bp_id, mf_id, cc_id, mpo_id)
      results = query(sparql)

      results.first[:hits_count]
    end

    def search(meo_id: '', tax_id: '', bp_id: '', mf_id: '', cc_id: '', mpo_id: '', limit: 25, offset: 0)
      sparql  = search_sparql(meo_id, tax_id, bp_id, mf_id, cc_id, mpo_id, limit, offset)
      results = query(sparql)

      return [] if results.empty?

      targets = [
        { name: 'genes',      sparql: find_genes_sparql( results.map {|b| "<#{b[:uniprot_id]}>" }.uniq.join(' ') ) },
        { name: 'gos',        sparql: find_gene_ontologies_sparql( results.map {|b| "<#{b[:uniprot_up]}>" }.uniq.join(' ') ) },
        { name: 'envs',       sparql: find_environments_sparql( results.map {|b| "<#{b[:taxonomy_id]}>" }.uniq.join(' ') ) },
        { name: 'phenotypes', sparql: find_phenotypes_sparql( results.map {|b| "<#{b[:taxonomy_id]}>" }.uniq.join(' ') ) }
      ]

      genes, gos, envs, phenotypes = nil, nil, nil, nil

      Parallel.map(targets, in_threads: 4) {|target|
        res = query(target[:sparql])
        case target[:name]
        when 'genes'      then genes = res
        when 'gos'        then gos = res
        when 'envs'       then envs = res
        when 'phenotypes' then phenotypes = res
        end
      }

      results.map do |result|
        select_genes      = genes.select {|g| g[:uniprot_id] == result[:uniprot_id] }
        select_gos        = gos.select {|g| g[:uniprot_up] == result[:uniprot_up] }
        select_envs       = envs.select {|e| e[:taxonomy_id] == result[:taxonomy_id] }
        select_phenotypes = phenotypes.select {|p| p[:taxonomy_id] == result[:taxonomy_id] }

        new(result, select_genes, select_gos, select_envs, select_phenotypes)
      end
    end
  end

  def initialize(up_tax, genes, gos, envs, phenotypes)
    @id         = up_tax[:uniprot_id].split('/').last
    @uri        = up_tax[:uniprot_id]
    @uniprot    = up_tax[:uniprot_up]
    @name       = up_tax[:recommended_name]
    @tax        = Taxonomy.new(up_tax[:taxonomy_id], up_tax[:taxonomy_name])
    @genes      = genes.map {|gene| Gene.new(gene[:togogenome]) }
    @gos        = gos.map {|go| GeneOntology.new(go[:quick_go_uri], go[:go_name]) }
    @envs       = envs.map {|env| Environment.new(env[:meo_id], env[:meo_name]) }
    @phenotypes = phenotypes.map {|phenotype| Phenotype.new(phenotype[:mpo_id], phenotype[:mpo_name]) }
  end

  attr_reader :id, :uri, :uniprot, :name, :tax, :genes, :gos, :envs, :phenotypes
end
