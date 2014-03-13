class Endpoint < Settingslogic
  source Rails.root.join(*%w(config endpoint.yml)).to_s
  namespace Rails.env
end
