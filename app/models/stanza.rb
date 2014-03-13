class Stanza < Settingslogic
  source Rails.root.join(*%w(config stanza.yml)).to_s
  namespace Rails.env
end
