module ApplicationHelper
  def page_tabs
    [
      {id: :facet,     name: 'Facet',        path: root_path},
      {id: :sequence,  name: 'Sequence',     path: sequence_index_path},
      {id: :converter, name: 'ID converter', path: converter_path},
      {id: :resolver,  name: 'ID resolver',  path: resolver_path}
    ]
  end
end
