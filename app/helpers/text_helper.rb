module TextHelper
  def link_to_report_page(report_type, stanza_attr)
    path = case report_type
           when 'genes'
             gene_path("#{stanza_attr['tax_id']}:#{stanza_attr['gene_id']}")
           when 'organisms'
             organism_path(stanza_attr['tax_id'])
           when 'environments'
             environment_path(stanza_attr['env_id'])
           end

    link_to('Report page', path, target: '_blank')
  end

  def stanza_prefix(stanza_url, stanza_attr)
    # パラメータ名に stanza_ のプリフィックスをつける
    ary = stanza_attr.map {|key, val| ["stanza_#{key}", val] }
    stanza_prefix_params = Hash[ary]

    {stanza: stanza_url}.merge(stanza_prefix_params)
  end
end
