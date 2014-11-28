module StanzaSearchHelper
  def link_to_stanza_list(stanza, query)
    id, name, count, enabled = stanza.values_at(:stanza_id, :stanza_name, :count, :enabled)
    label = enabled ? "#{name} (#{count})" : name

    link_to_if enabled, label, search_text_path(q: query, category: id)
  end

  def link_to_report_page(stanza)
    label, path =
      case stanza[:report_type]
      when 'genes'
        gene_id = "#{stanza[:stanza_query]['tax_id']}:#{stanza[:stanza_query]['gene_id']}"
        ["Gene #{gene_id}", gene_path(gene_id)]
      when 'organisms'
        tax_id = stanza[:stanza_query]['tax_id']
        ["Organism #{tax_id}", organism_path(tax_id)]
      when 'environments'
        env_id = stanza[:stanza_query]['env_id']
        ["Environment #{env_id}", environment_path(env_id)]
      end

    link_to(label, path, target: '_blank')
  end

  def stanza_prefix(stanza)
    # パラメータ名に stanza_ のプリフィックスをつける
    stanza_prefix_params = stanza[:stanza_query].map {|key, val| ["stanza_#{key}", val] }.to_h

    {stanza: stanza[:stanza_url]}.merge(stanza_prefix_params)
  end

  def stanza_collection
    stanza_ary = Stanza.all.sort_by {|s| s["name"] }.map {|s|
      TextSearch.searchable?(s['id']) ?  [s['name'], s['id']] : [s['name'], s['id'], {disabled: 'disabled'}]
    }

    [
      ['All', 'all'],
      ['Genes', 'gene_reports'],
      ['Organisms', 'organism_reports'],
      ['Environments', 'environment_reports'],
      ['--------------', {disabled: 'disabled'}]
    ] + stanza_ary
  end

  def textsearch_info(stanzas)
    start_page = (stanzas.current_page - 1) * TextSearch::PAGINATE[:per_page] + 1
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

    paginate @stanzas, window: window
  end
end
