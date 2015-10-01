require 'open-uri'

class StanzaSearch
  class SearchQuery
    def initialize(query)
      @raw = query
    end

    attr_reader :raw

    def tokens
      @tokens ||= begin
        scanner = StringScanner.new(@raw)
        scanner.skip /\s+/

        parse(scanner)
      end
    end

    def to_clause
      tokens.each_with_object('') {|token, acc|
        case token
        when :lparen
          acc << '('
        when :rparen
          acc << ')'
        when :or
          acc << ' OR '
        when :and
          acc << ' AND '
        else
          acc << "(text:#{token.inspect} OR id_text:#{token.inspect})"
        end
      }
    end

    private

    def parse(scanner, tokens = [])
      scanner.skip /\s+\z/

      return tokens if scanner.eos?

      tokens <<
        if scanner.scan(/"((?:[^\\"]|\\.)*)"/)
          scanner[1].gsub(/\\(.)/, '\1')
        elsif scanner.scan(/\(\s*/)
          :lparen
        elsif scanner.scan(/\s*\)/)
          :rparen
        elsif scanner.scan(/\s*OR\s*/)
          :or
        elsif scanner.scan(/\s*AND\s*|\s+/)
          :and
        else
          scanner.scan(/\S+(?<!\))/)
        end

      parse(scanner, tokens)
    end
  end

  PAGINATE = {per_page: 10}

  class << self
    def search(q)
      return nil unless q

      # XXX nanostanza は検索してない
      Stanza.ids.map {|id|
        search_by_stanza_id(q, id)
      }.group_by {|e|
        e[:report_type]
      }
    end

    def search_by_stanza_id(q, stanza_id, page = 1)
      stanza_data = Stanza.all.find {|s| s['id'] == stanza_id }
      result = get_with_cache(stanza_id, q, page)

      {
        enabled:     result.present?,
        urls:        (result ? result['response']['docs'].map {|doc| doc['@id']} : []),
        count:       (result ? result['response']['numFound'] : 0),
        stanza_id:   stanza_id,
        stanza_name: stanza_data['name'],
        stanza_uri:  stanza_data['uri'],
        report_type: stanza_data['report_type']
      }
    end

    private

    def get_with_cache(stanza_id, q, page)
      begin
        clause = SearchQuery.new(q).to_clause

        solr = RSolr.connect(url: "#{Endpoint.fulltextsearch}/#{stanza_id}")
        solr.paginate(page, PAGINATE[:per_page], 'select', params: {q: clause})
      rescue RSolr::Error::Http => e
        case e.response[:status]
        when 404
          nil
        when 400...500
          raise 'Could not full-text search in your query. Please request again by changing the query.'
        else
          raise 'Full-text search server is down ...'
        end
      end
    end
  end
end
