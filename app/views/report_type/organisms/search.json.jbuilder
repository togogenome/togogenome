json.iTotalRecords @total_count
json.iTotalDisplayRecords @hits_count
json.aaData do |json|
  json.array!(@results) do |p|
    json.organism_link     link_to(p.tax.name, organism_path(p.tax.id), target: '_blank')
    json.environment_links link_list(p.envs, 'environment')
    json.phenotype_links   link_list(p.phenotypes, 'phenotype')
  end
end
