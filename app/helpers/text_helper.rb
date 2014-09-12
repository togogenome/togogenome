module TextHelper
  def link_to_stanza_list(stanza, q)
    label = stanza[:enabled] ? "#{stanza[:stanza_name]} (#{stanza[:count]})" : stanza[:stanza_name]
    link_to_if stanza[:enabled], label, search_stanza_text_index_path(q: q, target: stanza[:stanza_id])
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
    ary = stanza[:stanza_query].map {|key, val| ["stanza_#{key}", val] }
    stanza_prefix_params = Hash[ary]

    {stanza: stanza[:stanza_url]}.merge(stanza_prefix_params)
  end

  def stanza_collection
    multiple_target = TextSearch::MULTIPLE_TARGET.map{|t| [t[:label], t[:key]] }

    single_target = Stanza.all.sort_by {|s| s["name"] }.map {|s|
      if %w(organism_names organism_phenotype).include?(s['id'])
        [s['name'], s['id']]
      else
        [s['name'], s['id'], {disabled: 'disabled'}]
      end
    }

    multiple_target + [['--------------', {disabled: 'disabled'}]] + single_target
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
