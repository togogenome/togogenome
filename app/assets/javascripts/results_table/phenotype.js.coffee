$ ->
  # 表示するデータを指定し初期化
  drawInfo.phenotype =
    dataTable: $("#phenotype_results").DataTable(
      ajax:
        url: "/report_type/phenotypes.json"
      columns: [
        {data: "phenotype_link"}
        {data: "category"}
        {data: "inhabitants"}
      ]
    )
    downloadCSV: '/report_type/phenotypes.csv'

  $("#phenotype_results").parent().find(".result-download-container").append "<a>Download CSV</a>"
  return
