module ReportTypeHelper
  def link_list(lists, target)
    content_tag(:ul) do
      lists.each do |item|
        concat content_tag(:li, link_to_item(item, target))
      end
    end
  end

  private
  def link_to_item(item, target)
    case target
    when 'gene'
      link_to(item.id, gene_path(item.id), target: '_blank')
    when 'gene_ontology'
      link_to(item.name, item.uri, target: '_blank')
    when 'environment'
      link_to(item.name, environment_path(item.id), target: '_blank')
    when 'phenotype'
      link_to(item.name, phenotype_path(item.id), target: '_blank')
    else
      raise('must not happen')
    end
  end
end
