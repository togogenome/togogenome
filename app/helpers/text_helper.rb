module TextHelper
  def link_to_report_page(report_type, entry_id)
    path = case report_type
           when 'genes'
             gene_path("#{entry_id['tax_id']}:#{entry_id['gene_id']}")
           when 'organisms'
             organism_path(entry_id['tax_id'])
           when 'environments'
             environment_path(entry_id['env_id'])
           end

    link_to('Report page', path, target: '_blank')
  end

  def stanza_prefix(stanza_url, entry_id)
    # パラメータ名に stanza_ のプリフィックスをつける
    ary = entry_id.map {|key, val| ["stanza_#{key}", val] }
    stanza_prefix_params = Hash[ary]

    {stanza: stanza_url}.merge(stanza_prefix_params)
  end
end
