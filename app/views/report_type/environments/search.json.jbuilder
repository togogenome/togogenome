json.sEcho @sEcho
json.iTotalRecords @total_count
json.iTotalDisplayRecords @hits_count
json.aaData do |json|
  json.array!(@proteins) do |e|
    json.environment_link link_to(e.name, environment_path(e.id), target: '_blank')
  end
end
