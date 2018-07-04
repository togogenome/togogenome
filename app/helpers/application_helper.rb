module ApplicationHelper
  def page_tabs
    [
      {id: :facet,     name: 'Facet',              path: root_path},
      {id: :compare,   name: 'Comparative genome', path: compare_path},
      {id: :sequence,  name: 'Sequence',           path: sequence_index_path},
      {id: :text,      name: 'Text',               path: text_index_path}
    ]
  end

  def report_tabs
    [
      {type: 'organism'},
      {type: 'gene'},
      {type: 'phenotype'},
      {type: 'environment'}
    ]
  end
end
