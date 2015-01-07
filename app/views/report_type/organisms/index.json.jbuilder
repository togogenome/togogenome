json.iTotalRecords @total_count
json.iTotalDisplayRecords @hits_count
json.aaData do |json|
  json.array!(@results) do |p|
    json.organism_link     link_to(p.tax.name, organism_path(p.tax.id), target: '_blank')
    json.environment_links link_list(p.envs, 'environment')
    json.development_links link_list(p.phenotypes['Development'], 'phenotype')
    json.growth_links      link_list(p.phenotypes['Growth'], 'phenotype')
    json.metabolism_links  link_list(p.phenotypes['Metabolism'], 'phenotype')
    json.morphology_links  link_list(p.phenotypes['Morphology'], 'phenotype')
    json.motility_links    link_list(p.phenotypes['Motility'], 'phenotype')
    json.serotype_links    link_list(p.phenotypes['Serotype'], 'phenotype')
    json.staining_links    link_list(p.phenotypes['Staining'], 'phenotype')
  end
end
