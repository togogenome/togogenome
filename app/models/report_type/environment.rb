module ReportType
  class Environment < Base
    class << self
      def addition_information(results)
        results.map do |result|
          Base::Environment.new(result[:meo_id], result[:meo_name])
        end
      end
    end
  end
end
