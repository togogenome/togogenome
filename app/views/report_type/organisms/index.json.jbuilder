json.iTotalRecords @total_count
json.iTotalDisplayRecords @hits_count
json.aaData do |json|
  json.array!(@results) do |r|
    json.organism_link     link_to(r.tax.name, organism_path(r.tax.id), target: '_blank')
    json.environment_links link_list(r.envs, 'environment')
    json.development_links link_list(r.phenotypes['Development'], 'phenotype')
    json.growth_links      link_list(r.phenotypes['Growth'], 'phenotype')
    json.metabolism_links  link_list(r.phenotypes['Metabolism'], 'phenotype')
    json.morphology_links  link_list(r.phenotypes['Morphology'], 'phenotype')
    json.motility_links    link_list(r.phenotypes['Motility'], 'phenotype')
    json.serotype_links    link_list(r.phenotypes['Serotype'], 'phenotype')
    json.staining_links    link_list(r.phenotypes['Staining'], 'phenotype')
    json.gene_num          r.stat.try(:gene_num_per_project_num)
    json.rrna_num          r.stat.try(:rrna_num_per_project_num)
    json.trna_num          r.stat.try(:trna_num_per_project_num)
    json.ncrna_num         r.stat.try(:ncrna_num_per_project_num)
  end
end
