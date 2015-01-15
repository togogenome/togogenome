json.iTotalRecords @total_count
json.iTotalDisplayRecords @hits_count
json.aaData do |json|
  json.array!(@results) do |r|
    json.environment_link link_to(r.environment.name, environment_path(r.environment.id), target: '_blank')
    json.category         r.environment.root
    json.inhabitants      r.environment.inhabitants
  end
end
