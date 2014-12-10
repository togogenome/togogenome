$ ->
  # 表示するデータを指定し初期化
  drawInfo.organism =
    dataTable: $("#organism_results").DataTable(
      ajax:
        url: "/report_type/organisms/search.json"
      columns: [
        {data: "organism_link"}
        {data: "environment_links"}
        {data: "phenotype_links"}
      ]
    )
    downloadCSV: '/report_type/organisms/search.csv'

  $("#organism_results").parent().find(".result-download-container").append "<a>Download CSV</a>"
  return
