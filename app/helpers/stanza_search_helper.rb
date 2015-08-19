module StanzaSearchHelper
  def link_to_stanza_list(stanza, query)
    id, name, count, enabled = stanza.values_at(:stanza_id, :stanza_name, :count, :enabled)
    label = enabled ? "#{name} (#{count})" : name

    link_to_if enabled, label, text_search_path(q: query, stanza_id: id)
  end

  def link_to_report_page(stanza)
    label = "#{stanza[:report_type].classify} #{stanza[:stanza_attr_id]}"

    link_to(label, stanza[:togogenome_url], target: '_blank')
  end

  def stanza_prefix(stanza)
    stanza_attr_id, report_type, stanza_id = stanza.values_at(:stanza_attr_id, :report_type, :stanza_id)

    case report_type
    when 'genes'
      gene_id, tax_id = stanza_attr_id.split(':')
      {stanza_gene_id: gene_id, stanza_tax_id: tax_id}
    when 'environments'
      {stanza_meo_id: stanza_attr_id}
    when 'organisms'
      {stanza_tax_id: stanza_attr_id}
    when 'phenotypes'
      {stanza_mpo_id: stanza_attr_id}
    end.merge(stanza: "#{Stanza.providers.togostanza.url}/#{stanza_id}")
  end

  def stanza_collection
    stanza_ary = Stanza.all.sort_by {|s| s["name"] }.map {|s|
      [s['name'], s['id'], {'data-search-target' => 'stanza'}]
    }

    [
      ['Genes',        'gene',        {'data-search-target' => 'category'}],
      ['Organisms',    'organism',    {'data-search-target' => 'category'}],
      ['Phenotypes',   'phenotype',   {'data-search-target' => 'category'}],
      ['Environments', 'environment', {'data-search-target' => 'category'}],
      ['--------------', {disabled: 'disabled'}]
    ] + stanza_ary
  end

  def textsearch_info(stanzas)
    start_page = (stanzas.current_page - 1) * StanzaSearch::PAGINATE[:per_page] + 1
    end_page   = start_page + stanzas.count - 1

    "Showing #{start_page} to #{end_page} of #{stanzas.total_count} stanzas"
  end

  def fixed_link_count_paginate(stanzas)
    first_page = 1
    last_page = stanzas.total_pages

    window = case stanzas.current_page
             when first_page, last_page
               4
             when (first_page + 1), (last_page - 1)
               3
             else
               2
             end

    paginate stanzas, window: window
  end
end
