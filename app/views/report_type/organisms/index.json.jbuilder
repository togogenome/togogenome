json.iTotalRecords @total_count
json.iTotalDisplayRecords @hits_count
json.aaData do |json|
  json.array!(@results) do |r|
    json.taxonomy          r.tax.taxonomy
    json.organism_link     link_to(r.tax.name, organism_path(r.tax.id), target: '_blank')
    json.genome_size       number_to_human(r.stat.try(:genome_size), units: {thousand: 'Kb', million: 'Mb', billion: 'Gb'})
    json.gene_num          number_with_delimiter(r.stat.try(:gene_num))
    json.rrna_num          number_with_delimiter(r.stat.try(:rrna_num))
    json.trna_num          number_with_delimiter(r.stat.try(:trna_num))
    json.ncrna_num         number_with_delimiter(r.stat.try(:ncrna_num))
    json.environment_links link_list(r.envs, 'environment')
    json.temperature       "TODO"
    json.morphology        link_to_if(r.morphology.mpo_name, r.morphology.mpo_name, r.morphology.mpo_url, target: '_blank'){}
    json.energy_source     link_to_if(r.energy_source.mpo_name, r.energy_source.mpo_name, r.energy_source.mpo_url, target: '_blank'){}
  end
end
