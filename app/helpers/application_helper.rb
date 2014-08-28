module ApplicationHelper
  def stanza_height(stanza, stanza_attr)
    if stanza.keys.include?('height')
      stanza_attr.merge!({stanza_height: stanza.height})
    end
    stanza_attr
  end

  # http://localhost:9292/stanza/protein_names?tax_id=1016998
  # => {stanza: "http://localhost:9292/stanza/protein_names", stanza_tax_id: '1016998'}}
  def url2stanza_params(url)
    url_without_query = url.sub(/\?.*/, '')

    # パラメータ名に stanza_ のプリフィックをつける
    ary = Rack::Utils.parse_query(URI(url).query).map {|key, val| ["stanza_#{key}", val] }
    stanza_prefix_params = Hash[ary]

    {stanza: url_without_query}.merge(stanza_prefix_params)
  end
end
