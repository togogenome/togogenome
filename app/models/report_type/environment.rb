module ReportType
  class Environment < Base
    class << self
      def addition_information(results)
        results.map do |env|
          Struct.new(:id, :name).new(env[:meo_id], env[:meo_name])
        end
      end
    end
  end
end
