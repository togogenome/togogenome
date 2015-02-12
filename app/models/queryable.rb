module Queryable
  extend ActiveSupport::Concern

  module ClassMethods
    def query(sparql)
      Rails.logger.info "===== SPARQL (EP: #{Endpoint.uri}) =====\n" + sparql

      result = Rails.cache.fetch Digest::MD5.hexdigest(sparql), expires_in: 1.month do
        client = HTTPClient.new
        client.post_content(Endpoint.uri, { query: sparql }, { Accept: "application/sparql-results+json"} )
      end
      result_json = JSON.parse(result)

      return result_json['boolean'] if result_json.has_key?('boolean') # SELECT じゃなく ASK で聞いた時はこちらを返す
      return [] if result_json['results']['bindings'].empty?

      result_json['results']['bindings'].map do |b|
        result_json['head']['vars'].each_with_object({}) do |key, hash|
          # OPTIONAL 指定で結果が無い場合、head vars には SELECT対象の変数が key として含まれるが、results にはその key 自体も含まれない
          hash[key.to_sym] = b[key]['value'] if b.has_key?(key)
        end
      end
    end
  end
end
