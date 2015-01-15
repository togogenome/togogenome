json.iTotalRecords @total_count
json.iTotalDisplayRecords @hits_count
json.aaData do |json|
  json.array!(@results) do |r|
    json.gene_link         link_to(r.gene_and_taxonomy.gene_id, r.gene_and_taxonomy.gene_uri, target: '_blank')
    json.protein_links     link_list(r.proteins, 'protein')
    json.protein_names     list(r.proteins.map(&:name))
    json.go_links          link_list(r.gos, 'gene_ontology')
    json.organism_link     link_to(r.gene_and_taxonomy.taxonomy_name, organism_path(r.gene_and_taxonomy.taxonomy_id), target: '_blank')
  end
end
