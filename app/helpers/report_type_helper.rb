module ReportTypeHelper
  def list(items)
    content_tag(:ul) do
      items.uniq.each do |item|
        concat content_tag(:li, item)
      end
    end
  end

  def link_list(items, target)
    return nil unless items
    content_tag(:ul) do
      items.uniq.each do |item|
        concat content_tag(:li, link_to_item(item, target))
      end
    end
  end

  private
  def link_to_item(item, target)
    case target
    when 'protein'
      link_to(item.id, item.uniprot_link, target: '_blank')
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
