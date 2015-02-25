module ReportType
  class Organism < Base
    include SparqlBuilder::Organism

    class << self
      def count(meo_id: '', tax_id: '', bp_id: '', mf_id: '', cc_id: '', mpo_id: '')
        select_clause =  "SELECT COUNT(DISTINCT ?taxonomy_id) AS ?hits_count"
        sparql = build_base_sparql(meo_id, tax_id, bp_id, mf_id, cc_id, mpo_id, select_clause)

        results = query(sparql)

        results.first[:hits_count]
      end

      def search(meo_id: '', tax_id: '', bp_id: '', mf_id: '', cc_id: '', mpo_id: '', limit: 25, offset: 0)
        select_clause, order_clause = "SELECT DISTINCT ?taxonomy_id ?taxonomy_name ?category_name ?sub_category_name", 'ORDER BY ?category_name ?sub_category_name'
        sparql = build_base_sparql(meo_id, tax_id, bp_id, mf_id, cc_id, mpo_id, select_clause, order_clause, limit, offset)

        results = query(sparql)

        return [] if results.empty?

        taxids = results.map {|b| "<#{b[:taxonomy_id]}>" }.uniq.join(' ')

        sparqls = [
          find_environments_sparql(PREFIX, ONTOLOGY, taxids),
          find_genome_stats_sparql(PREFIX, ONTOLOGY, taxids),
          find_temperature_sparql(PREFIX, ONTOLOGY, taxids),
          find_morphology_sparql(PREFIX, ONTOLOGY, taxids),
          find_energy_source_sparql(PREFIX, ONTOLOGY, taxids)
        ]

        envs, stats, temperatures, morphologies, energy_sources = Parallel.map(sparqls, in_threads: 4) {|sparql|
          query(sparql)
        }

        results.map do |result|
          select_envs           = envs.select {|e| e[:taxonomy_id] == result[:taxonomy_id] }
          select_stat           = stats.find {|s| s[:taxonomy_id] == result[:taxonomy_id] }
          select_temperatures   = temperatures.select {|m| m[:taxonomy_id] == result[:taxonomy_id] }
          select_morphologies   = morphologies.select {|m| m[:taxonomy_id] == result[:taxonomy_id] }
          select_energy_sources = energy_sources.select {|m| m[:taxonomy_id] == result[:taxonomy_id] }

          new(result, select_envs, select_stat, select_temperatures, select_morphologies, select_energy_sources)
        end
      end
    end

    def initialize(up_tax, envs, stat, temperatures, morphologies, energy_sources)
      @uniprot_taxonomy, @envs, @stat, @temperatures, @morphologies, @energy_sources = up_tax, envs, stat, temperatures, morphologies, energy_sources
    end

    def tax
      category, sub_category, uri, name = @uniprot_taxonomy.values_at(:category_name, :sub_category_name, :taxonomy_id, :taxonomy_name)

      OpenStruct.new(
        category: "#{category} / #{sub_category}",
        uri:      uri,
        name:     name,
        id:       uri.split('/').last
      )
    end

    def envs
      @envs.map do |env|
        OpenStruct.new(id: env[:meo_id], name: env[:meo_name])
      end
    end

    def temperature
      return nil if @temperatures.empty?

      range, label = @temperatures.first.values_at(:habitat_temperature_range, :habitat_temperature_range_label)
      value = @temperatures.map {|t| t[:value].to_i }.sort.join(' - ')

      OpenStruct.new(
        id:    range.split('#').last,
        label: "#{label} (#{value}°C)"
      )
    end

    def morphologies
      @morphologies.map do |morphology|
        OpenStruct.new(
          id:   morphology[:mpo_url].split('#').last,
          name: morphology[:mpo_name]
        )
      end
    end

    def energy_sources
      @energy_sources.map do |energy_source|
        OpenStruct.new(
          id:   energy_source[:mpo_url].split('#').last,
          name: energy_source[:mpo_name]
        )
      end
    end

    def stat
      OpenStruct.new(@stat) if @stat
    end
  end
end
