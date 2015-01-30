json.iTotalRecords @total_count
json.iTotalDisplayRecords @hits_count
json.aaData do |json|
  json.array!(@results) do |r|
    json.phenotype_link link_to(r.phenotype.name, phenotype_path(r.phenotype.id), target: '_blank')
    json.category         r.phenotype.root
    json.inhabitants      r.phenotype.inhabitants
  end
end
