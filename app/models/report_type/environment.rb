module ReportType
  class Environment < Base
    class << self
      def addition_information(results)
        meos = results.map {|r| "<#{r[:meo_id]}>" }.uniq.join(' ')

        sparqls = [
          find_environment_root_sparql(meos)
        ]

        meo_roots = Parallel.map(sparqls, in_threads: 4) {|sparql|
          query(sparql)
        }.first

        results.map do |result|
          select_meo_root = meo_roots.select {|r| r[:meo_id] == result[:meo_id] }.first
          new(result, select_meo_root)
        end
      end
    end

    def initialize(meo, meo_root)
      @environment, @environment_root = meo, meo_root
    end

    def environment
      Struct.new(:uri, :name, :root){
        def id
          uri.split('/').last
        end
      }.new(@environment[:meo_id], @environment[:meo_name], @environment_root[:name])
    end
  end
end
