class Stanza < Settingslogic
  source Rails.root.join(*%w(config stanza.yml)).to_s
  namespace Rails.env

  def ids
    providers.togostanza.reject {|key| key == 'url' }.values.flatten.map {|s| s['id'] }
  end

  def all
    providers.togostanza.reject {|key| key == 'url' }.flat_map {|report_type, stanzas|
      stanzas.map {|s| s.merge('report_type' => report_type) }
    }
  end
end
