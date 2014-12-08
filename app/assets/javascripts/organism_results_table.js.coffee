$ ->
  # 表示するデータを指定し初期化
  dataTables.organism = $("#organism_results").DataTable(
    ajax:
      url: "/proteins/organism/search.json"
      data: (d) ->
        d.taxonomy = $("#_taxonomy_id").val()
        d.environment = $("#_environment_id").val()
        d.biological_process = $("#_biological_process_id").val()
        d.molecular_function = $("#_molecular_function_id").val()
        d.cellular_component = $("#_cellular_component_id").val()
        d.phenotype = $("#_phenotype_id").val()
        return

      error: ->
        alert "failing query..."
        return

    columns: [
      {data: "organism_link"}
      {data: "environment_links"}
      {data: "phenotype_links"}
    ]
    paginationSlider: null
  )
  $("#organism_results").parent().find(".result-download-container").append "<a>Download CSV</a>"
  return
