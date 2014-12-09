json.sEcho @sEcho
json.iTotalRecords @total_count
json.iTotalDisplayRecords @hits_count
json.aaData do |json|
  json.array!(@proteins) do |p|
    json.name              p.name
    json.gene_links        link_list(p.genes, 'gene')
    json.entry_identifier  link_to(p.id, p.uniprot, target: '_blank')
    json.go_links          link_list(p.gos, 'gene_ontology')
    json.organism_link     link_to(p.tax.name, organism_path(p.tax.id), target: '_blank')
    json.environment_links link_list(p.envs, 'environment')
    json.phenotype_links   link_list(p.phenotypes, 'phenotype')
  end
end
