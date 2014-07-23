class TextSearch
  class << self
    def search(q)
      {
        stanzas: [
          {
            name: 'stanza name',
            count: 3,
            urls: [
              'http://example.com/1',
              'http://example.com/2',
              'http://example.com/3'
            ]
          }
        ]
      }
    end
  end
end
