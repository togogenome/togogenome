module ApplicationHelper
  def stanza_height(stanza, stanza_attr)
    if stanza.keys.include?('height')
      stanza_attr.merge!({stanza_height: stanza.height})
    end
    stanza_attr
  end

  def page_tabs
    [
      {id: :facet,     name: 'Facet',        path: root_path},
      {id: :sequence,  name: 'Sequence',     path: sequence_index_path},
      {id: :converter, name: 'ID converter', path: converter_path},
      {id: :resolver,  name: 'ID resolver',  path: resolver_path}
    ]
  end
end
