$ ->
  # 表示するデータを指定し初期化
  dataTables.environment = $("#environment_results").DataTable(
    ajax:
      url: "/proteins/environment/search.json"
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
      {data: "environment_link"}
    ]
    paginationSlider: null
  )
  $("#environment_results").parent().find(".result-download-container").append "<a>Download CSV</a>"
  return
