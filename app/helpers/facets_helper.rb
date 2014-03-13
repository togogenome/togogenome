module FacetsHelper
  def facet_title(facet)
    case facet
    when 'biological_process', 'molecular_function', 'cellular_component'
      "GO: #{facet.tableize.classify}"
    else
      facet.tableize.classify
    end
  end

  def search_placeholder(facet)
    case facet
    when 'environment'
      'fresh water'
    when 'taxonomy'
      'Nostocales'
    when 'biological_process'
      'cellular nitrogen compound metabolic process'
    when 'molecular_function'
      'metal ion binding'
    when 'cellular_component'
      'cytoplasm'
    when 'phenotype'
      'Motile'
    end
  end
end
