module ApplicationHelper
  def stanza_height(stanza, stanza_attr)
    if stanza.keys.include?('height')
      stanza_attr.merge!({stanza_height: stanza.height})
    end
    stanza_attr
  end
end
