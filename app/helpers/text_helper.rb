module TextHelper
  def link_to_report_page(stanza)
    path = case stanza[:report_type]
           when 'genes'
             gene_path("#{stanza[:stanza_query]['tax_id']}:#{stanza[:stanza_query]['gene_id']}")
           when 'organisms'
             organism_path(stanza[:stanza_query]['tax_id'])
           when 'environments'
             environment_path(stanza[:stanza_query]['env_id'])
           end

    link_to('Report page', path, target: '_blank')
  end

  def stanza_prefix(stanza)
    # パラメータ名に stanza_ のプリフィックスをつける
    ary = stanza[:stanza_query].map {|key, val| ["stanza_#{key}", val] }
    stanza_prefix_params = Hash[ary]

    {stanza: stanza[:stanza_url]}.merge(stanza_prefix_params)
  end

  def stanza_collection
    search_target = [['All', 'all'], ['Genes', 'gene_reports'], ['Organisms', 'organism_reports'], ['Environments', 'environment_reports']]
    search_target + Stanza.all.map{|s| [s['name'], s['id']] }
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
