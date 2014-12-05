json.sEcho @sEcho
json.iTotalRecords @total_count
json.iTotalDisplayRecords @hits_count
json.aaData do |json|
  json.array!(@proteins) do |p|
    json.organism_link     link_to(p.tax.name, organism_path(p.tax.id), target: '_blank')
  end
end
